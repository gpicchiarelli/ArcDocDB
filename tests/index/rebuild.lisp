;;;; Ricostruzione v2: fixture C4 indipendenti; nessuna esecuzione al caricamento.
;;;; OWNER: runner seriale isolato; ogni fixture possiede indice, digest e scratch.
;;;; SHARED: symbol-function solo nelle FI bounded, ripristinato in ogni uscita.
(in-package #:arcdocdb.index.primary.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-IDX-005
(declaim (ftype (function (primary-fixture)
                         (values p:frammento-indice p::digests-frammento p::digests-frammento &optional))
                rebuild-input))
(defun rebuild-input (fixture)
  "Pre: fixture seriale. Post: digest per slot originale; sentinel nei soli slot non vivi."
  (let ((capacity (p::indice-primario-capacity (primary-fixture-index fixture))))
    (values (primary-current fixture)
            (make-array capacity :element-type '(unsigned-byte 32) :initial-element #xffffffff)
            (make-array capacity :element-type '(unsigned-byte 32) :initial-element #xffffffff))))

;;; REQ: REQ-IDX-005 REQ-IDX-001
(declaim (ftype (function (primary-fixture p::digests-frammento p::digests-frammento
                         fixnum octets u64 u32 u32 &key (:location u64)) s::contenuto-slot)
                rebuild-put))
(defun rebuild-put (fixture highs lows slot key csn high low &key (location #x1700000100))
  "Pre: SLOT scelto dalla fixture, non ricavato da probe. Post: payload e digest nello slot atteso."
  (let* ((expected (primary-put fixture key csn high low :location location))
         (source (primary-current fixture high))
         (sample (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))
    (is (eq :live (s:leggi-slot-v2 (p::frammento-indice-bank source) slot sample)))
    (primary-check-payload sample expected)
    (let ((offset (ldb (byte 32 0) (aref sample 2))))
      (is (equalp key (subseq (p::frammento-indice-arena source) offset (+ offset (length key))))))
    (is (= (logand low 127) (aref (p::frammento-indice-controls source) slot)))
    (setf (aref highs slot) high (aref lows slot) low)
    expected))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice boolean fixnum fixnum) integer)
                rebuild-budget))
(defun rebuild-budget (fixture source split first-bytes second-bytes)
  "Oracolo C4: root con frammenti distinti + directory + 41*C e arena minima per candidato."
  (let* ((index (primary-fixture-index fixture))
         (global (max (p::root-indice-depth (p::indice-primario-root index))
                      (+ (p::frammento-indice-depth source) (if split 1 0))))
         (slots (* 41 (p::indice-primario-capacity index))))
    (+ (primary-root-bytes fixture) (* 8 (expt 2 global)) slots (max 1 first-bytes)
       (if split (+ slots (max 1 second-bytes)) 0))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice list) null) rebuild-source-unchanged))
(defun rebuild-source-unchanged (fixture source before)
  "Pre: immagine prima della costruzione. Post: identita root/arena e tutto il sorgente invariati.
La revisione dell'indice puo avanzare per la copia nei candidati; salute verificata dal chiamante."
  (let ((after (primary-image fixture source)))
    (is (eq (first before) (first after)))
    (is (eq (second before) (second after)))
    (is (equalp (nthcdr 4 before) (nthcdr 4 after))))
  nil)

;;; REQ: REQ-IDX-005 REQ-AFF-004
(declaim (ftype (function (function symbol keyword) null) rebuild-error))
(defun rebuild-error (thunk type reason)
  "Pre: un rifiuto atteso. Post: classe e reason esatti, nessun altro errore assorbito."
  (is (handler-case (progn (funcall thunk) nil)
        (arcdocdb-error (condition)
          (is (typep condition type)) (is (eq reason (error-reason condition))) t)))
  nil)

;;; REQ: REQ-IDX-005 REQ-AFF-008
(declaim (ftype (function (symbol function function) t) rebuild-with-function-fi))
(defun rebuild-with-function-fi (symbol replacement-factory thunk)
  "Solo C4 seriale: acquisisce una definizione, installa FI e la ripristina anche su errore."
  (let ((original (symbol-function symbol)))
    (unwind-protect
         (progn (setf (symbol-function symbol) (funcall replacement-factory original))
                (funcall thunk))
      (setf (symbol-function symbol) original))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(declaim (ftype (function (primary-fixture p:frammento-indice p::digests-frammento
                         p::digests-frammento integer boolean symbol keyword) null)
                rebuild-refusal))
(defun rebuild-refusal (fixture source highs lows budget split type reason)
  "Pre: input che deve fallire prima dei candidati. Post: zero factory, revisioni e sorgente invariati."
  (let ((calls 0) (h (copy-seq highs)) (l (copy-seq lows)))
    (rebuild-with-function-fi
     'p:crea-frammento-indice
     (lambda (original)
       (lambda (&rest arguments) (incf calls) (apply original arguments)))
     (lambda ()
       (primary-refusal fixture source
                        (lambda () (p:ricostruisci-frammento-indice
                                    (primary-fixture-index fixture) source highs lows budget :split-p split))
                        type reason)))
    (is (zerop calls)) (is (equalp h highs)) (is (equalp l lows)))
  nil)

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice p::digests-frammento
                         p::digests-frammento boolean fixnum fixnum fixnum)
                         p:pubblicazione-indice) rebuild-plan))
(defun rebuild-plan (fixture source highs lows split first-bytes second-bytes references)
  "Pre: byte attesi scelti dalla fixture. Post: cinque valori, piano prepared e sorgente immutato."
  (let* ((index (primary-fixture-index fixture)) (before (primary-image fixture source))
         (h (copy-seq highs)) (l (copy-seq lows))
         (budget (rebuild-budget fixture source split first-bytes second-bytes))
         (values (multiple-value-list
                  (p:ricostruisci-frammento-indice index source highs lows budget :split-p split)))
         (plan (first values)))
    (is (= 5 (length values))) (is (typep plan 'p:pubblicazione-indice))
    (is (equal (list (p::indice-primario-capacity index) (+ first-bytes second-bytes) references budget)
               (rest values)))
    (is (eq :prepared (p::pubblicazione-indice-state plan)))
    (is (eq source (p::pubblicazione-indice-source plan)))
    (is (eq (first before) (p::pubblicazione-indice-expected plan)))
    (is (eq :building (p::frammento-indice-exposure (p::pubblicazione-indice-first plan))))
    (is (= (+ (third before) (p::frammento-indice-live source)) (p::indice-primario-revision index)))
    (is (= (p::indice-primario-revision index) (p::pubblicazione-indice-revision plan)))
    (is (eq :open (p::indice-primario-health index)))
    (rebuild-source-unchanged fixture source before)
    (is (equalp h highs)) (is (equalp l lows))
    plan))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:pubblicazione-indice) null) rebuild-publish))
(defun rebuild-publish (fixture plan)
  "Pre: piano fresco. Post: CAS root, generation+1, source retired/frozen e piano monouso."
  (let* ((index (primary-fixture-index fixture)) (old (p::pubblicazione-indice-expected plan))
         (source (p::pubblicazione-indice-source plan)) (revision (p::indice-primario-revision index)))
    (is (null (p:pubblica-directory-indice plan)))
    (is (eq (p::pubblicazione-indice-replacement plan) (p::indice-primario-root index)))
    (is (not (eq old (p::indice-primario-root index))))
    (is (= (1+ (p::root-indice-generation old))
           (p::root-indice-generation (p::indice-primario-root index))))
    (is (= (1+ revision) (p::indice-primario-revision index)))
    (is (eq :published (p::pubblicazione-indice-state plan)))
    (is (eq :retired (p::frammento-indice-exposure source)))
    (is (eq :frozen (s::banco-slot-state (p::frammento-indice-bank source)))))
  nil)

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-rebuild-original-slots-and-compacted-offsets
  (let ((f (primary-fixture)) (a (primary-key 11 12))
        (b (primary-key 21 22 23)) (c (primary-key 31)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      ;; Insertion order 16,0,17 differs from scanning and packed candidate order.
      (let ((pa (rebuild-put f highs lows 16 a 11 0 #x805))
            (pb (rebuild-put f highs lows 0 b 12 #x80000000 7))
            (pc (rebuild-put f highs lows 17 c 13 #xc0000000 #x809)))
        (let* ((before (primary-image f source))
               (plan (rebuild-plan f source highs lows nil 6 0 1)))
          (primary-live f a 0 #x805 pa 0)
          (primary-live f b #x80000000 7 pb 2)
          (rebuild-publish f plan)
          (primary-live f a 0 #x805 pa 3)
          (primary-live f b #x80000000 7 pb 0)
          (primary-live f c #xc0000000 #x809 pc 5)
          (is (= 6 (length (p::frammento-indice-arena (primary-current f)))))
          (is (equalp (nth 11 before) (s::banco-slot-words (p::frammento-indice-bank source)))))))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-rebuild-split-verified
  ;; Exact name consumed by the isolated runtime mutant split-child-wrong.
  (let ((f (primary-fixture)) (a (primary-key 1 2)) (b (primary-key 3))
        (c (primary-key 4 5 6)) (d (primary-key 7 8)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (let ((pa (rebuild-put f highs lows 16 a 101 #xc0000000 #x803))
            (pb (rebuild-put f highs lows 0 b 102 0 5))
            (pc (rebuild-put f highs lows 17 c 103 #x80000000 #x807))
            (pd (rebuild-put f highs lows 1 d 104 #x40000000 9)))
        (let* ((plan (rebuild-plan f source highs lows t 3 5 2))
               (first (p::pubblicazione-indice-first plan)) (second (p::pubblicazione-indice-second plan)))
          (is (= 1 (p::frammento-indice-depth first) (p::frammento-indice-depth second)))
          (is (= 0 (p::frammento-indice-prefix first)))
          (is (= 1 (p::frammento-indice-prefix second)))
          (is (= 2 (p::frammento-indice-live first) (p::frammento-indice-live second)))
          (is (eq :building (p::frammento-indice-exposure second)))
          (rebuild-publish f plan)
          (is (eq first (primary-current f 0))) (is (eq second (primary-current f #x80000000)))
          (primary-live f a #xc0000000 #x803 pa 0)
          (primary-live f b 0 5 pb 0)
          (primary-live f c #x80000000 #x807 pc 2)
          (primary-live f d #x40000000 9 pd 1))))))

;;; REQ: REQ-IDX-005 REQ-LIM-003 REQ-IDX-001
(deftest test-REQ-IDX-005-rebuild-u64-max-key-and-reset-sequence
  (let* ((key (make-array 65535 :element-type '(unsigned-byte 8)))
         (f (primary-fixture :capacity 16 :arena-bytes 65535)))
    (dotimes (i 65535) (setf (aref key i) (mod i 251)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (let ((payload (rebuild-put f highs lows 0 key #xffffffffffffffff #xffffffff 127
                                  :location #xffffffff00000100)))
        (primary-fi-sequence source 0 (- (expt 2 62) 2))
        (let ((plan (rebuild-plan f source highs lows nil 65535 0 1)))
          (rebuild-publish f plan)
          (primary-live f key #xffffffff 127 payload 0)
          (let ((target (primary-current f #xffffffff)))
            (is (equalp key (p::frammento-indice-arena target)))
            (is (= 2 (aref (s::banco-slot-words (p::frammento-indice-bank target)) 3)))))))))

;;; REQ: REQ-IDX-005 REQ-IDX-006
(deftest test-REQ-IDX-005-rebuild-deletion-compacts-live-bytes
  (let ((f (primary-fixture)) (dead (primary-key 1 2 3 4 5))
        (a (primary-key 6 7)) (b (primary-key 8 9 10)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 dead 1 0 1)
      (let ((pa (rebuild-put f highs lows 1 a 2 0 3))
            (pb (rebuild-put f highs lows 2 b 3 0 5)))
        (is (primary-delete f dead 0 1))
        (setf (aref highs 0) #xffffffff (aref lows 0) #xffffffff)
        (let ((plan (rebuild-plan f source highs lows nil 5 0 1)))
          (is (= 10 (p::frammento-indice-used source)))
          (is (= 254 (aref (p::frammento-indice-controls source) 0)))
          (rebuild-publish f plan)
          (primary-live f a 0 3 pa 0) (primary-live f b 0 5 pb 2)
          (primary-no-output f dead 0 1 :absent)
          (let ((target (primary-current f)))
            (is (= 2 (p::frammento-indice-live target)))
            (is (= 5 (length (p::frammento-indice-arena target))))
            (is (not (find 254 (p::frammento-indice-controls target))))))))))

;;; REQ: REQ-IDX-005
(deftest test-REQ-IDX-005-rebuild-empty-fragment
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (let ((plan (rebuild-plan f source highs lows nil 0 0 1)))
        (is (null (p::pubblicazione-indice-second plan)))
        (rebuild-publish f plan)
        (is (= 1 (length (p::frammento-indice-arena (primary-current f)))))
        (primary-no-output f (primary-key 1) 0 1 :absent)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-rebuild-empty-split
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (let ((plan (rebuild-plan f source highs lows t 0 0 2)))
        (dolist (target (list (p::pubblicazione-indice-first plan) (p::pubblicazione-indice-second plan)))
          (is (= 1 (length (p::frammento-indice-arena target))))
          (is (zerop (p::frammento-indice-live target))))
        (rebuild-publish f plan)
        (primary-no-output f (primary-key 1) 0 1 :absent)
        (primary-no-output f (primary-key 2) #x80000000 2 :absent)))))

;;; REQ: REQ-IDX-005
(deftest test-REQ-IDX-005-rebuild-split-one-empty-child
  (let ((f (primary-fixture)) (key (primary-key 1 2 3)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (let* ((payload (rebuild-put f highs lows 16 key 1 #x80000000 #x807))
             (plan (rebuild-plan f source highs lows t 0 3 2)))
        (is (= 1 (length (p::frammento-indice-arena (p::pubblicazione-indice-first plan)))))
        (rebuild-publish f plan)
        (primary-live f key #x80000000 #x807 payload 0)
        (primary-no-output f key 0 #x807 :absent)))))

;;; REQ: REQ-AFF-008 REQ-IDX-005
(deftest test-REQ-AFF-008-rebuild-transient-budget
  ;; Exact name consumed by the runtime mutant (> payload budget) -> (= payload budget).
  (let ((f (primary-fixture)) (key (primary-key 1 2)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 key 1 0 7)
      (let ((exact (rebuild-budget f source nil 2 0)))
        (rebuild-refusal f source highs lows (1- exact) nil
                         'resource-exhausted :primary-directory-transient-budget)
        (let ((plan (rebuild-plan f source highs lows nil 2 0 1)))
          (rebuild-publish f plan))))))

;;; REQ: REQ-AFF-008 REQ-IDX-007
(deftest test-REQ-AFF-008-rebuild-directory-budget-before-candidates
  (dolist (directory-budget '(8 16))
    (let ((f (primary-fixture :capacity 16 :arena-bytes 1 :directory-budget directory-budget)))
      (multiple-value-bind (source highs lows) (rebuild-input f)
        (if (= directory-budget 8)
            (rebuild-refusal f source highs lows (rebuild-budget f source t 0 0) t
                             'resource-exhausted :primary-directory-memory-budget)
            (rebuild-publish f (rebuild-plan f source highs lows t 0 0 2)))))))

;;; REQ: REQ-AFF-008 REQ-IDX-005
(deftest test-REQ-AFF-008-rebuild-fragment-budget-conditions
  ;; Pure budget helper: synthetic measured lengths exercise otherwise defensive branches.
  ;; With a valid source under its immutable budget, a compacted child cannot grow larger.
  (let* ((f (primary-fixture :capacity 16 :arena-bytes 1 :fragment-budget 657))
         (index (primary-fixture-index f)) (source (primary-current f))
         (root (p::indice-primario-root index)))
    (primary-refusal f source
                     (lambda () (p::budget-ricostruzione index root source nil 2 1 10000))
                     'resource-exhausted :primary-fragment-memory-budget)
    (primary-refusal f source
                     (lambda () (p::budget-ricostruzione index root source t 1 2 10000))
                     'resource-exhausted :primary-fragment-memory-budget)
    (is (equal (list 0 (+ 665 8 657))
               (multiple-value-list (p::budget-ricostruzione index root source nil 1 2 10000))))
    (is (equal (list 1 (+ 665 16 657 657))
               (multiple-value-list (p::budget-ricostruzione index root source t 1 1 10000))))))

;;; REQ: REQ-AFF-008 REQ-IDX-005
(deftest test-REQ-AFF-008-rebuild-invalid-shape-and-budget
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-refusal f source (subseq highs 0 31) lows 10000 nil
                       'invalid-argument :primary-rebuild-configuration)
      (rebuild-refusal f source highs (subseq lows 0 31) 10000 nil
                       'invalid-argument :primary-rebuild-configuration)
      (dolist (budget (list 0 (1+ most-positive-fixnum)))
        (rebuild-refusal f source highs lows budget nil
                         'invalid-argument :primary-rebuild-configuration)))))

;;; REQ: REQ-AFF-008 REQ-IDX-007
(deftest test-REQ-AFF-008-rebuild-depth-exhausted-only-for-split
  (let ((f (primary-fixture :max-depth 0)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-refusal f source highs lows 10000 t 'resource-exhausted :primary-directory-depth)
      (rebuild-publish f (rebuild-plan f source highs lows nil 0 0 1)))))

;;; REQ: REQ-IDX-005 REQ-IDX-001
(deftest test-REQ-IDX-005-rebuild-wrong-digest-fingerprint
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 (primary-key 1) 1 0 7)
      (setf (aref lows 0) 8)
      (rebuild-refusal f source highs lows 10000 nil 'invalid-argument :primary-rebuild-digest))))

;;; REQ: REQ-IDX-005 REQ-IDX-001
(deftest test-REQ-IDX-005-rebuild-wrong-digest-lookup-group
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 16 (primary-key 1) 1 0 #x807)
      ;; Same H2=7, wrong initial group with EMPTY; fingerprint alone cannot reject this.
      (setf (aref lows 16) 7)
      (rebuild-refusal f source highs lows 10000 nil 'invalid-argument :primary-rebuild-digest))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-rebuild-wrong-digest-source-prefix
  (let ((f (primary-fixture)))
    (multiple-value-bind (old highs lows) (rebuild-input f)
      (rebuild-publish f (rebuild-plan f old highs lows t 0 0 2)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 (primary-key 1) 1 0 7)
      (setf (aref highs 0) #x80000000)
      (rebuild-refusal f source highs lows 10000 nil 'invalid-argument :primary-fragment-prefix))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-rebuild-plan-stale-after-source-update
  (let ((f (primary-fixture)) (key (primary-key 1 2)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 key 1 0 7)
      (let ((plan (rebuild-plan f source highs lows nil 2 0 1)))
        (let ((updated (primary-put f key 2 0 7 :location #x1800000200)))
          (primary-refusal f source (lambda () (p:pubblica-directory-indice plan))
                           'invalid-argument :primary-directory-stale-plan)
          (is (eq :prepared (p::pubblicazione-indice-state plan)))
          (primary-live f key 0 7 updated 0)
          (rebuild-publish f (rebuild-plan f source highs lows nil 2 0 1))
          (primary-live f key 0 7 updated 0))))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-rebuild-second-construction-stales-first-plan
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 (primary-key 1) 1 0 7)
      (let* ((first (rebuild-plan f source highs lows nil 1 0 1))
             (second (rebuild-plan f source highs lows nil 1 0 1)))
        (primary-refusal f source (lambda () (p:pubblica-directory-indice first))
                         'invalid-argument :primary-directory-stale-plan)
        (rebuild-publish f second)
        (primary-refusal f (primary-current f) (lambda () (p:pubblica-directory-indice second))
                         'invalid-argument :primary-directory-stale-plan)))))

;;; REQ: REQ-AFF-008 REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-AFF-008-rebuild-revision-exhaustion-before-candidates
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 (primary-key 1) 1 0 7)
      (let* ((index (primary-fixture-index f)) (limit (expt 2 60)))
        (setf (p::indice-primario-revision index) (- limit 2))
        (rebuild-refusal f source highs lows 10000 nil
                         'resource-exhausted :primary-index-revision-exhausted)
        ;; One copy and one publication still fit at this exact boundary.
        (setf (p::indice-primario-revision index) (- limit 3))
        (rebuild-publish f (rebuild-plan f source highs lows nil 1 0 1))
        (is (= (1- limit) (p::indice-primario-revision index)))))))

;;; REQ: REQ-AFF-008 REQ-IDX-007
(deftest test-REQ-AFF-008-rebuild-generation-exhaustion-before-candidates
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (let* ((index (primary-fixture-index f)) (root (p::indice-primario-root index))
             (directory (p::root-indice-directory root)) (limit (expt 2 60)))
        ;; FI replaces the immutable root; never SETF its read-only generation.
        (setf (p::indice-primario-root index) (p::%make-root-indice 0 (1- limit) directory))
        (rebuild-refusal f source highs lows 10000 nil
                         'resource-exhausted :primary-directory-generation-exhausted)
        (setf (p::indice-primario-root index) (p::%make-root-indice 0 (- limit 2) directory))
        (rebuild-publish f (rebuild-plan f source highs lows nil 0 0 1))
        (is (= (1- limit) (p::root-indice-generation (p::indice-primario-root index))))))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-rebuild-corrupted-copy-location
  ;; Exact name consumed by skip-copy-verification. FI corrupts BUILDING only, after real copy.
  (let* ((f (primary-fixture :capacity 16)) (index (primary-fixture-index f))
         (function-before (symbol-function 'p::copia-ricostruzione)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 (primary-key 1 2) 1 0 7)
      (let ((before (primary-image f source)) (injected 0))
        (rebuild-with-function-fi
         'p::copia-ricostruzione
         (lambda (original)
           (lambda (&rest arguments)
             (prog1 (apply original arguments)
               (let* ((target (third arguments)) (bank (p::frammento-indice-bank target)))
                 (is (eq :building (p::frammento-indice-exposure target)))
                 (is (not (eq target source)))
                 (incf (aref (s::banco-slot-words bank) 1) 16)
                 (incf injected)))))
         (lambda ()
           (rebuild-error (lambda () (p:ricostruisci-frammento-indice index source highs lows 10000))
                          'invariant-violation :primary-rebuild-copy-mismatch)))
        (is (= 1 injected))
        (is (eq function-before (symbol-function 'p::copia-ricostruzione)))
        (is (eq :faulted (p::indice-primario-health index)))
        (rebuild-source-unchanged f source before)
        (rebuild-error (lambda () (p:ricostruisci-frammento-indice index source highs lows 10000))
                       'invariant-violation :primary-index-faulted)))))

;;; REQ: REQ-IDX-005
(deftest test-REQ-IDX-005-rebuild-copy-comparison
  ;; Independent conditions of IR-D06; END fixture is defensive, not a retained lookup.
  (let ((original (primary-payload (primary-key 1 2) #xffffffffffffffff)))
    (dotimes (field 5)
      (let ((copy (copy-seq original)))
        (setf (aref copy field)
              (logxor (aref copy field) (if (= field 2) (ash 1 32) 1)))
        (is (not (p::copia-ricostruzione-uguale-p original copy)))))
    (let ((copy (copy-seq original)))
      (incf (aref copy 2) 17) ; Only the local arena offset may differ.
      (is (p::copia-ricostruzione-uguale-p original copy)))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(declaim (ftype (function (primary-fixture p:frammento-indice p::digests-frammento
                         p::digests-frammento keyword) null) rebuild-source-fault))
(defun rebuild-source-fault (fixture source highs lows reason)
  "Pre: FI source deja appliquee. Post: seul health change, zero candidat, cause exacte conservee."
  (let* ((index (primary-fixture-index fixture)) (before (primary-image fixture source)) (calls 0))
    (rebuild-with-function-fi
     'p:crea-frammento-indice
     (lambda (original) (lambda (&rest arguments) (incf calls) (apply original arguments)))
     (lambda () (rebuild-error
                 (lambda () (p:ricostruisci-frammento-indice index source highs lows 10000))
                 'invariant-violation reason)))
    (is (zerop calls)) (is (eq :faulted (p::indice-primario-health index)))
    (let ((after (primary-image fixture source)))
      ;; Mask only two terminal health fields; root, revision, exposure, state and bytes stay exact.
      (setf (nth 3 before) :health (nth 3 after) :health
            (nth 8 before) :health (nth 8 after) :health)
      (is (primary-image-equal before after))))
  nil)

;;; REQ: REQ-IDX-005 REQ-IDX-001
(deftest test-REQ-IDX-005-rebuild-duplicate-source-key
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 (primary-key 1 2) 1 0 7)
      (rebuild-put f highs lows 1 (primary-key 3 4) 2 0 7)
      ;; FI preserves well-formed payload/count/H2, but makes slot 1 rediscover slot 0.
      (replace (p::frammento-indice-arena source) (primary-key 1 2) :start1 2)
      (rebuild-refusal f source highs lows 10000 nil 'invalid-argument :primary-rebuild-digest))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-rebuild-source-control-corruption
  (dolist (scenario '(:reserved :live-marked-empty :empty-marked-live))
    (let ((f (primary-fixture)))
      (multiple-value-bind (source highs lows) (rebuild-input f)
        (unless (eq scenario :empty-marked-live)
          (rebuild-put f highs lows 0 (primary-key 1) 1 0 7))
        (setf (aref (p::frammento-indice-controls source) 0)
              (ecase scenario (:reserved 128) (:live-marked-empty 255) (:empty-marked-live 7)))
        (rebuild-source-fault f source highs lows
                              (ecase scenario
                                (:reserved :primary-control-corrupt)
                                (:live-marked-empty :primary-rebuild-live-control)
                                (:empty-marked-live :primary-rebuild-empty-control)))))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-rebuild-source-bank-corruption-propagates
  (dolist (scenario '(:payload :sequence :odd))
    (let ((f (primary-fixture)))
      (multiple-value-bind (source highs lows) (rebuild-input f)
        (rebuild-put f highs lows 0 (primary-key 1) 1 0 7)
        (ecase scenario
          (:payload (setf (aref (s::banco-slot-words (p::frammento-indice-bank source)) 0) 0))
          (:sequence (primary-fi-sequence source 0 (expt 2 62)))
          (:odd (primary-fi-sequence source 0 3)))
        (rebuild-source-fault f source highs lows
                              (ecase scenario
                                (:payload :index-slot-inconsistent)
                                (:sequence :index-slot-sequence-corrupt)
                                (:odd :primary-rebuild-writer-state)))
        (unless (eq scenario :odd)
          (is (eq :faulted (s::banco-slot-health (p::frammento-indice-bank source)))))))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-rebuild-probe-bank-corruption-before-slot-scan
  ;; Slot 0 probes group 16 first. Corrupt slot 16 must fault the index before that scan iteration.
  (let ((f (primary-fixture)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 16 (primary-key 1 2) 1 0 #x807)
      (rebuild-put f highs lows 0 (primary-key 3 4) 2 0 7)
      (setf (aref lows 0) #x807)
      (setf (aref (s::banco-slot-words (p::frammento-indice-bank source)) (* 16 5)) 0)
      (rebuild-source-fault f source highs lows :index-slot-inconsistent))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-rebuild-source-arena-and-live-count-corruption
  (dolist (scenario '(:used :range :count))
    (let ((f (primary-fixture :arena-bytes 8)))
      (multiple-value-bind (source highs lows) (rebuild-input f)
        (rebuild-put f highs lows 0 (primary-key 1 2) 1 0 7)
        (ecase scenario
          (:used (setf (p::frammento-indice-used source) 9))
          (:range (setf (p::frammento-indice-used source) 1))
          (:count (setf (p::frammento-indice-live source) 2)))
        (rebuild-source-fault f source highs lows
                              (ecase scenario
                                (:used :primary-rebuild-arena-used)
                                (:range :primary-rebuild-key-range)
                                (:count :primary-rebuild-live-count)))))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-rebuild-copy-lookup-false-is-terminal
  (let ((f (primary-fixture :capacity 16)))
    (multiple-value-bind (source highs lows) (rebuild-input f)
      (rebuild-put f highs lows 0 (primary-key 1 2) 1 0 7)
      (let ((before (primary-image f source)))
        (rebuild-with-function-fi
         'p::copia-ricostruzione
         (lambda (original)
           (lambda (&rest arguments)
             (prog1 (apply original arguments)
               ;; Candidate remains live/count-correct, but its key cannot be found.
               (fill (p::frammento-indice-controls (third arguments)) 255))))
         (lambda ()
           (rebuild-error
            (lambda () (p:ricostruisci-frammento-indice
                        (primary-fixture-index f) source highs lows 10000))
            'invariant-violation :primary-rebuild-copy-mismatch)))
        (is (eq :faulted (p::indice-primario-health (primary-fixture-index f))))
        (rebuild-source-unchanged f source before)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(deftest test-REQ-IDX-005-rebuild-cold-abort-preserves-source
  (dolist (after-copy '(nil t))
    (let ((f (primary-fixture)))
      (multiple-value-bind (source highs lows) (rebuild-input f)
        (rebuild-put f highs lows 0 (primary-key 1) 1 0 7)
        (let* ((previous (rebuild-plan f source highs lows nil 1 0 1))
               (before (primary-image f source)) (index (primary-fixture-index f)))
          (rebuild-with-function-fi
           'p::copia-ricostruzione
           (lambda (original)
             (lambda (&rest arguments)
               (when after-copy (apply original arguments))
               (error 'invalid-argument :reason :rebuild-test-cold-abort)))
           (lambda ()
             (rebuild-error (lambda () (p:ricostruisci-frammento-indice index source highs lows 10000))
                            'invalid-argument :rebuild-test-cold-abort)))
          (is (eq :open (p::indice-primario-health index)))
          (rebuild-source-unchanged f source before)
          (is (= (+ (third before) (if after-copy 1 0)) (p::indice-primario-revision index)))
          (if after-copy
              (primary-refusal f source (lambda () (p:pubblica-directory-indice previous))
                               'invalid-argument :primary-directory-stale-plan)
              (rebuild-publish f previous)))))))
