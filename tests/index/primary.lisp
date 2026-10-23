;;;; Test funzionali del contratto esistente; i candidati rebuild/split sono manuali.
(in-package #:arcdocdb.index.primary.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-AFF-003 REQ-IDX-001
(deftest test-REQ-AFF-003-primary-harness-and-empty-root
  "Pre: harness caricato. Post: macro senza effetti in espansione e root vuota coerente."
  (is (equal (macroexpand-1 '(deftest sample-primary-test "Fixture." :ok))
             '(progn (declaim (ftype (function () t) sample-primary-test))
               (defun sample-primary-test () "Fixture." :ok)
               (pushnew 'sample-primary-test *tests*))))
  (let* ((f (primary-fixture)) (fragment (primary-current f))
         (root (p::indice-primario-root (primary-fixture-index f))))
    (is (= 0 (p::root-indice-depth root) (p::root-indice-generation root)))
    (is (eq fragment (aref (p::root-indice-directory root) 0)))
    (is (= 0 (p::frammento-indice-live fragment) (p::frammento-indice-used fragment)))
    (primary-no-output f (primary-key 0) 0 0 :absent)))

;;; REQ: REQ-IDX-001 REQ-LIM-003
(deftest test-REQ-IDX-001-primary-binary-collisions-and-span
  "Pre: digest collidenti fidati. Post: confronto esatto di lunghezza/byte, inclusi zero e span."
  (let* ((f (primary-fixture))
         (keys (list (primary-key 0 255 1) (primary-key 0 255 2)
                     (primary-key 0 255) (primary-key 0 255 1 0)))
         (expected (loop for key in keys for csn from 1
                         collect (primary-put f key csn 0 5))))
    (loop for key in keys for payload in expected do (primary-live f key 0 5 payload))
    (primary-no-output f (primary-key 0 255 3) 0 5 :absent)
    (let* ((span (primary-key 88 0 255 1 99))
           (key (first keys)) (payload (primary-payload key 20 :location #x9900000400)))
      (is (null (p:pubblica-chiave-indice
                 (primary-fixture-index f) (primary-current f) span 1 4 0 5 payload
                 (primary-fixture-writer f))))
      (primary-live f key 0 5 payload 0)
      (is (eq :live (p:leggi-indice-primario
                    (primary-fixture-index f) span 1 4 0 5 (primary-fixture-reader f)
                    (primary-fixture-output f))))
      (primary-check-payload (primary-fixture-output f) payload 0))))

;;; REQ: REQ-IDX-001 REQ-IDX-006
(deftest test-REQ-IDX-001-primary-full-group-wrap-and-deleted-not-empty
  "Pre: gruppo finale pieno senza EMPTY. Post: wrap al primo gruppo e DELETED non termina."
  (let* ((f (primary-fixture :capacity 32)) (fragment (primary-current f))
         (group-low (ash 16 7)) (target (primary-key 17)))
    (dotimes (i 16) (primary-put f (primary-key i) (1+ i) 0 (+ group-low i)))
    (let ((expected (primary-put f target 30 0 (+ group-low 16))))
      (is (loop for slot from 16 below 32
                always (< (aref (p::frammento-indice-controls fragment) slot) 128)))
      (is (primary-delete f (primary-key 0) 0 group-low))
      (is (= p::+ctrl-deleted+ (aref (p::frammento-indice-controls fragment) 16)))
      (primary-live f target 0 (+ group-low 16) expected 16)
      (primary-no-output f (primary-key 99) 0 (+ group-low 31) :absent))))

;;; REQ: REQ-IDX-006 REQ-IDX-003
(deftest test-REQ-IDX-006-primary-delete-idempotence-and-reuse-new-fingerprint
  "Pre: collisioni nel gruppo. Post: delete conserva arena, riuso cambia H2 senza ripristinare EMPTY."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (a (primary-key 1 0))
         (b (primary-key 2 0)) (c (primary-key 3 0)))
    (primary-put f a 1 0 7)
    (let ((expected-b (primary-put f b 2 0 7))
          (arena-before (copy-seq (p::frammento-indice-arena fragment))))
      (is (primary-delete f a 0 7))
      (is (= 1 (p::frammento-indice-live fragment)))
      (is (= 4 (p::frammento-indice-used fragment)))
      (is (equalp arena-before (p::frammento-indice-arena fragment)))
      (is (= p::+ctrl-deleted+ (aref (p::frammento-indice-controls fragment) 0)))
      (let ((before (primary-image f fragment)))
        (is (not (primary-delete f a 0 7)))
        (is (primary-image-equal before (primary-image f fragment))))
      (primary-no-output f a 0 7 :absent)
      (primary-live f b 0 7 expected-b 2)
      (let ((expected-c (primary-put f c 3 0 23)))
        (is (= 23 (aref (p::frammento-indice-controls fragment) 0)))
        (is (= 2 (p::frammento-indice-live fragment)))
        (primary-live f c 0 23 expected-c 4)
        (primary-live f b 0 7 expected-b 2)))))

;;; REQ: REQ-IDX-001 REQ-IDX-003
(deftest test-REQ-IDX-001-primary-upsert-csn-increasing-and-key-stable
  "Pre: chiave gia viva. Post: solo CSN crescente, offset/count/byte chiave invariati."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (key (primary-key 1 2 3)))
    (primary-put f key 10 0 1)
    (dolist (csn '(10 9))
      (primary-refusal f fragment (lambda () (primary-put f key csn 0 1))
                       'invalid-argument :primary-csn-not-increasing))
    (let ((arena-before (copy-seq (p::frammento-indice-arena fragment)))
          (expected (primary-put f key 11 0 1 :location #xff00000400 :extra 9)))
      (is (= 1 (p::frammento-indice-live fragment)))
      (is (= 3 (p::frammento-indice-used fragment)))
      (is (equalp arena-before (p::frammento-indice-arena fragment)))
      (is (not (p::contesto-indice-busy (primary-fixture-writer f))))
      (primary-live f key 0 1 expected 0))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-primary-prefix-refusals-before-mutation
  "Pre: candidato del prefisso zero a profondita uno. Post: digest del ramo uno rifiutato."
  (let* ((f (primary-fixture)) (index (primary-fixture-index f))
         (candidate (primary-candidate f 1 0)) (key (primary-key 5)))
    (primary-refusal f candidate
                     (lambda () (primary-put f key 1 #x80000000 5 :fragment candidate))
                     'invalid-argument :primary-fragment-prefix)
    (primary-refusal f candidate
                     (lambda () (p:rimuovi-chiave-indice
                                 index candidate key 0 1 #x80000000 5 (primary-fixture-writer f)))
                     'invalid-argument :primary-fragment-prefix)
    (primary-put f key 1 #x7fffffff 5 :fragment candidate)
    (primary-no-output f key #x7fffffff 5 :absent)))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(deftest test-REQ-IDX-005-primary-owner-refusals-preserve-both-domains
  "Pre: frammento di una seconda Serie. Post: nessun cambiamento in entrambe le Serie."
  (let* ((f (primary-fixture)) (other (primary-fixture)) (foreign (primary-current other))
         (key (primary-key 8)) (other-before (primary-image other foreign)))
    (primary-refusal f (primary-current f)
                     (lambda () (primary-put f key 1 0 8 :fragment foreign))
                     'invalid-argument :primary-fragment-owner)
    (primary-refusal f (primary-current f)
                     (lambda () (p:estendi-arena-indice
                                 (primary-fixture-index f) foreign 512 +primary-test-budget+))
                     'invalid-argument :primary-fragment-owner)
    (is (primary-image-equal other-before (primary-image other foreign)))))

;;; REQ: REQ-IDX-005 REQ-IDX-003
(deftest test-REQ-IDX-005-primary-frozen-fragment-readable-never-writable
  "Pre: banco congelato esplicitamente dalla fixture. Post: lettura viva, mutazioni rifiutate."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (key (primary-key 7))
         (expected (primary-put f key 1 0 7)))
    (is (null (s:congela-banco-slot (p::frammento-indice-bank fragment))))
    (primary-live f key 0 7 expected 0)
    (primary-refusal f fragment
                     (lambda () (primary-put f key 2 0 7 :fragment fragment))
                     'invalid-argument :index-slot-frozen)
    (primary-refusal f fragment
                     (lambda () (p:estendi-arena-indice
                                 (primary-fixture-index f) fragment 512 +primary-test-budget+))
                     'invalid-argument :index-slot-frozen)))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-primary-arena-growth-budget-and-offsets
  "Pre: arena piccola. Post: budget esatto ammesso, vecchio array immutato e offset conservati."
  (let* ((f (primary-fixture :arena-bytes 4)) (index (primary-fixture-index f))
         (fragment (primary-current f)) (a (primary-key 1 2 3)) (b (primary-key 4 5 6))
         (expected-a (primary-put f a 1 0 1))
         (old (p::frammento-indice-arena fragment)) (old-copy (copy-seq old))
         (budget (+ (primary-root-bytes f) 8)))
    (primary-refusal f fragment (lambda () (primary-put f b 2 0 2))
                     'resource-exhausted :primary-key-arena-full)
    (primary-refusal f fragment (lambda () (p:estendi-arena-indice index fragment 8 (1- budget)))
                     'resource-exhausted :primary-arena-transient-budget)
    (primary-refusal f fragment (lambda () (p:estendi-arena-indice index fragment 4 budget))
                     'invalid-argument :primary-arena-configuration)
    (is (null (p:estendi-arena-indice index fragment 8 budget)))
    (is (not (eq old (p::frammento-indice-arena fragment))))
    (let ((expected-b (primary-put f b 2 0 2)))
      (primary-live f a 0 1 expected-a 0)
      (primary-live f b 0 2 expected-b 3))
    (is (equalp old-copy old))))

;;; REQ: REQ-LIM-003 REQ-IDX-001
(deftest test-REQ-LIM-003-primary-key-65535-and-invalid-lengths
  "Pre: chiave binaria al limite v2. Post: 65535 byte integri; zero/65536/mismatch rifiutati."
  (let* ((f (primary-fixture :arena-bytes 65535)) (fragment (primary-current f))
         (key (make-array 65535 :element-type '(unsigned-byte 8) :initial-element 0)))
    (setf (aref key 0) 255 (aref key 65534) 17)
    (let ((expected (primary-put f key 1 #xffffffff #xffffffff)))
      (primary-live f key #xffffffff #xffffffff expected 0))
    (dolist (length '(0 65536))
      (let ((bad (make-array length :element-type '(unsigned-byte 8) :initial-element 0)))
        (primary-refusal f fragment (lambda () (primary-read f bad 0 0))
                         'invalid-argument :primary-key-length)))
    (let ((wrong (primary-payload (primary-key 1 2) 2)))
      (primary-refusal f fragment
                       (lambda () (primary-put f (primary-key 1) 2 0 1 :source wrong))
                       'invalid-argument :primary-source-key-length))))

;;; REQ: REQ-IDX-001 REQ-LIM-003
(deftest test-REQ-IDX-001-primary-u64-csn-through-maximum
  "Pre: versioni prima/dopo il limite fixnum. Post: 64 bit conservati, senza wrap al massimo."
  (let* ((f (primary-fixture)) (key (primary-key 255 0)) (fragment (primary-current f)))
    (dolist (csn (list most-positive-fixnum (1+ most-positive-fixnum)
                      #x8000000000000000 #xffffffffffffffff))
      (let ((expected (primary-put f key csn 0 127)))
        (primary-live f key 0 127 expected 0)))
    (primary-refusal f fragment (lambda () (primary-put f key #xffffffffffffffff 0 127))
                     'invalid-argument :primary-csn-not-increasing)
    (primary-refusal f fragment (lambda () (primary-put f key 1 0 127))
                     'invalid-argument :primary-csn-not-increasing)))

;;; REQ: REQ-IDX-003 REQ-IDX-007
(deftest test-REQ-IDX-003-primary-eight-collision-samples-one-budget
  "Pre: nove chiavi con H2 uguale. Post: ottava leggibile, nona oltre budget, output preservato."
  (let ((f (primary-fixture)))
    (dotimes (i 9) (primary-put f (primary-key i) (1+ i) 0 4))
    (dotimes (i 8)
      (primary-live f (primary-key i) 0 4 (primary-payload (primary-key i) (1+ i)))
      (is (= (- 7 i) (p::contesto-indice-remaining (primary-fixture-reader f)))))
    (primary-no-output f (primary-key 8) 0 4 :retry-limit)
    (is (zerop (p::contesto-indice-remaining (primary-fixture-reader f))))
    (primary-no-output f (primary-key 99) 0 4 :retry-limit)
    (is (primary-delete f (primary-key 8) 0 4))
    (primary-no-output f (primary-key 99) 0 4 :absent)
    (is (zerop (p::contesto-indice-remaining (primary-fixture-reader f))))))

;;; REQ: REQ-IDX-003 REQ-IDX-007
(deftest test-REQ-IDX-003-primary-collisions-and-odd-retries-share-eight
  "Pre: tre collisioni stabili poi seqlock dispari. Post: budget comune esaurito, cleanup e recupero."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (key (primary-key 7))
         (bank (p::frammento-indice-bank fragment)))
    (dotimes (i 8) (primary-put f (primary-key i) (1+ i) 0 9))
    (let ((sequence (aref (s::banco-slot-words bank)
                          (+ (s::base-slot bank 3) s::+slot-sequence+))))
      (unwind-protect
           (progn
             (primary-fi-sequence fragment 3 (1+ sequence))
             (primary-no-output f key 0 9 :retry-limit)
             (is (zerop (p::contesto-indice-remaining (primary-fixture-reader f)))))
        (primary-fi-sequence fragment 3 sequence)))
    (primary-live f key 0 9 (primary-payload key 8))))

;;; REQ: REQ-IDX-003 REQ-CON-004
(deftest test-REQ-CON-004-primary-output-preserved-miss-and-context-refusals
  "Pre: buffer privati e contesto libero. Post: miss senza scrittura; alias/rientro senza cleanup altrui."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (key (primary-key 1))
         (reader (primary-fixture-reader f)) (writer (primary-fixture-writer f)))
    (primary-put f key 1 0 1)
    (primary-no-output f (primary-key 2) 0 1 :absent)
    (signals invalid-argument
      (p:leggi-indice-primario (primary-fixture-index f) key 0 1 0 1 reader
                              (p::contesto-indice-words reader)) :primary-output-alias)
    (signals invalid-argument
      (p:pubblica-chiave-indice (primary-fixture-index f) fragment key 0 1 0 1
                               (p::contesto-indice-words writer) writer) :primary-source-alias)
    (setf (p::contesto-indice-busy reader) t)
    (unwind-protect
         (progn
           (signals invalid-argument (primary-read f key 0 1) :primary-context-busy)
           (is (p::contesto-indice-busy reader)))
      (setf (p::contesto-indice-busy reader) nil))
    (primary-live f key 0 1 (primary-payload key 1))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(deftest test-REQ-IDX-005-primary-load-slot-credit-and-revision-preflight
  "Pre: capacita minima piena a 7/8. Post: update ammesso; load/credito/revisione rifiutati prima."
  (let* ((f (primary-fixture :capacity 16)) (fragment (primary-current f))
         (index (primary-fixture-index f)) (key (primary-key 0)))
    (dotimes (i 14) (primary-put f (primary-key i) (1+ i) 0 i))
    (primary-refusal f fragment (lambda () (primary-put f (primary-key 14) 15 0 14))
                     'resource-exhausted :primary-fragment-load)
    (primary-put f key 20 0 0)
    (primary-fi-sequence fragment 0 (- s::+slot-sequence-limit+ 2))
    (primary-refusal f fragment (lambda () (primary-put f key 21 0 0))
                     'resource-exhausted :primary-slot-rebuild-required)
    (primary-refusal f fragment (lambda () (primary-delete f key 0 0))
                     'resource-exhausted :primary-slot-rebuild-required)
    (primary-fi-sequence fragment 0 4)
    (let ((revision (p::indice-primario-revision index)))
      (unwind-protect
           (progn
             (setf (p::indice-primario-revision index) (1- p::+revision-limit+))
             (primary-refusal f fragment (lambda () (primary-put f key 21 0 0))
                              'resource-exhausted :primary-index-revision-exhausted))
        (setf (p::indice-primario-revision index) revision)))
    (primary-live f key 0 0 (primary-payload key 20) 0)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-006 REQ-AFF-008
(declaim (ftype (function (primary-fixture p:frammento-indice octets integer integer u32 u32
                         &key (:rimozione boolean)) null) primary-preflight-preserved))
(defun primary-preflight-preserved (fixture fragment key start end high low &key (rimozione nil))
  "Solo fixture: successo senza cambi a dominio, chiave o budget reader; scratch writer non osservato."
  (let* ((context (primary-fixture-writer fixture)) (before (primary-image fixture fragment))
         (key-before (copy-seq key)) (remaining (p::contesto-indice-remaining context)))
    (is (null (p:verifica-capienza-mutazione-indice
               (primary-fixture-index fixture) fragment key start end high low context :rimozione rimozione)))
    (is (primary-image-equal before (primary-image fixture fragment)))
    (is (equalp key-before key))
    (is (= remaining (p::contesto-indice-remaining context)))
    (is (not (p::contesto-indice-busy context))))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-LIM-003 REQ-AFF-008
(deftest test-REQ-IDX-003-primary-mutation-preflight-span-probe-and-no-reservation
  "Pre: collisioni nel secondo gruppo e slot zero senza credito. Post: stesso LOW, span esatto e nessuna prenotazione."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (low (+ (ash 16 7) 37))
         (key (primary-key 2 3)) (span (primary-key 88 2 3 99)) (new (primary-key 3 3)))
    (primary-put f (primary-key 1 3) 1 0 low)
    (primary-put f key 2 0 low)
    (primary-fi-sequence fragment 0 (- s::+slot-sequence-limit+ 2))
    (dotimes (attempt 3)
      (primary-preflight-preserved f fragment span 1 3 0 low)
      (primary-preflight-preserved f fragment span 1 3 0 low :rimozione t)
      (primary-preflight-preserved f fragment new 0 2 0 low))
    (let ((payload (primary-put f key 3 0 low)))
      (primary-live f key 0 low payload 2)
      (is (= 2 (p::frammento-indice-live fragment)))
      (is (= 4 (p::frammento-indice-used fragment))))))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-AFF-008
(deftest test-REQ-IDX-005-primary-mutation-preflight-load-and-update
  "Pre: 28 chiavi su 32. Post: nuova chiave rifiutata senza effetti, update e DELETE ammessi."
  (let* ((f (primary-fixture :capacity 32)) (fragment (primary-current f))
         (index (primary-fixture-index f)) (context (primary-fixture-writer f))
         (key (primary-key 0)) (new (primary-key 28)))
    (dotimes (i 28) (primary-put f (primary-key i) (1+ i) 0 i))
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index fragment new 0 1 0 28 context))
                     'resource-exhausted :primary-fragment-load)
    (is (not (p::contesto-indice-busy context)))
    (primary-refusal f fragment (lambda () (primary-put f new 40 0 28))
                     'resource-exhausted :primary-fragment-load)
    (primary-preflight-preserved f fragment key 0 1 0 0)
    (primary-put f key 40 0 0)
    (primary-preflight-preserved f fragment (primary-key 99) 0 1 0 99 :rimozione t)
    (primary-preflight-preserved f fragment key 0 1 0 0 :rimozione t)
    (is (primary-delete f key 0 0))
    (primary-preflight-preserved f fragment new 0 1 0 28)
    (let ((payload (primary-put f new 41 0 28)))
      (primary-live f new 0 28 payload 28)
      (is (= 28 (p::frammento-indice-live fragment)))
      (is (= 29 (p::frammento-indice-used fragment))))))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-006 REQ-LIM-003 REQ-AFF-008
(deftest test-REQ-IDX-005-primary-mutation-preflight-arena-and-deleted-key
  "Pre: arena di 64 byte con quattro chiavi da 16. Post: update senza arena nuova; DELETE non recupera byte."
  (let* ((f (primary-fixture :arena-bytes 64)) (fragment (primary-current f))
         (index (primary-fixture-index f)) (context (primary-fixture-writer f))
         (keys (loop for i below 5 collect
                 (make-array 16 :element-type '(unsigned-byte 8) :initial-element i)))
         (key (first keys)) (new (fifth keys)))
    (dotimes (i 4) (primary-put f (nth i keys) (1+ i) 0 i))
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index fragment new 0 16 0 4 context))
                     'resource-exhausted :primary-key-arena-full)
    (is (not (p::contesto-indice-busy context)))
    (primary-refusal f fragment (lambda () (primary-put f new 10 0 4))
                     'resource-exhausted :primary-key-arena-full)
    (primary-preflight-preserved f fragment key 0 16 0 0)
    (primary-put f key 10 0 0)
    (primary-preflight-preserved f fragment key 0 16 0 0 :rimozione t)
    (is (primary-delete f key 0 0))
    (is (= 64 (p::frammento-indice-used fragment)))
    (primary-preflight-preserved f fragment key 0 16 0 0 :rimozione t)
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index fragment key 0 16 0 0 context))
                     'resource-exhausted :primary-key-arena-full)
    (primary-refusal f fragment (lambda () (primary-put f key 11 0 0))
                     'resource-exhausted :primary-key-arena-full)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-006 REQ-AFF-008
(deftest test-REQ-IDX-003-primary-mutation-preflight-credit-and-absent-delete
  "Pre: slot senza credito, poi ultimo credito prima di DELETE. Post: assenza gratuita e riuso DELETED soggetto al credito."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (index (primary-fixture-index f))
         (context (primary-fixture-writer f)) (bank (p::frammento-indice-bank fragment))
         (key (primary-key 1)) (absent (primary-key 9)))
    (primary-put f key 1 0 7)
    (primary-fi-sequence fragment 0 (- s::+slot-sequence-limit+ 2))
    (dolist (rimozione '(nil t))
      (primary-refusal f fragment
                       (lambda () (p:verifica-capienza-mutazione-indice
                                   index fragment key 0 1 0 7 context :rimozione rimozione))
                       'resource-exhausted :primary-slot-rebuild-required)
      (is (not (p::contesto-indice-busy context))))
    (primary-preflight-preserved f fragment absent 0 1 0 7 :rimozione t)
    (primary-fi-sequence fragment 0 (- s::+slot-sequence-limit+ 4))
    (dotimes (attempt 3)
      (primary-preflight-preserved f fragment key 0 1 0 7 :rimozione t))
    (is (= 1 (s:credito-scrittura-slot bank 0)))
    (is (primary-delete f key 0 7))
    (is (= 0 (s:credito-scrittura-slot bank 0)))
    (is (= p::+ctrl-deleted+ (aref (p::frammento-indice-controls fragment) 0)))
    (primary-preflight-preserved f fragment key 0 1 0 7 :rimozione t)
    (let ((before (primary-image f fragment)))
      (is (not (primary-delete f key 0 7)))
      (is (primary-image-equal before (primary-image f fragment))))
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index fragment key 0 1 0 7 context))
                     'resource-exhausted :primary-slot-rebuild-required)
    (primary-refusal f fragment (lambda () (primary-put f key 2 0 7))
                     'resource-exhausted :primary-slot-rebuild-required)))

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-IDX-007 REQ-AFF-008
(deftest test-REQ-IDX-007-primary-mutation-preflight-revision-and-absent-delete
  "Pre: revisione esaurita. Post: PUT nuovo/update e DELETE presente rifiutati, DELETE assente senza effetti."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (index (primary-fixture-index f))
         (context (primary-fixture-writer f)) (key (primary-key 1)) (absent (primary-key 9)))
    (primary-put f key 1 0 3)
    (let ((revision (p::indice-primario-revision index)))
      (unwind-protect
           (progn
             (setf (p::indice-primario-revision index) (1- p::+revision-limit+))
             (dolist (rimozione '(nil t))
               (primary-refusal f fragment
                                (lambda () (p:verifica-capienza-mutazione-indice
                                            index fragment key 0 1 0 3 context :rimozione rimozione))
                                'resource-exhausted :primary-index-revision-exhausted))
             (primary-refusal f fragment
                              (lambda () (p:verifica-capienza-mutazione-indice index fragment absent 0 1 0 3 context))
                              'resource-exhausted :primary-index-revision-exhausted)
             (primary-refusal f fragment (lambda () (primary-delete f key 0 3))
                              'resource-exhausted :primary-index-revision-exhausted)
             (primary-preflight-preserved f fragment absent 0 1 0 3 :rimozione t)
             (let ((before (primary-image f fragment)))
               (is (not (primary-delete f absent 0 3)))
               (is (primary-image-equal before (primary-image f fragment))))
             (is (not (p::contesto-indice-busy context))))
        (setf (p::indice-primario-revision index) revision)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-CON-004 REQ-LIM-003 REQ-AFF-008
(deftest test-REQ-IDX-005-primary-mutation-preflight-domain-span-and-context-guards
  "Pre: dominio/span/contesto non ammessi. Post: reason canonici, nessun effetto o rilascio del contesto altrui."
  (let* ((f (primary-fixture)) (fragment (primary-current f)) (index (primary-fixture-index f))
         (context (primary-fixture-writer f)) (key (primary-key 1))
         (other (primary-fixture)) (foreign (primary-current other))
         (other-before (primary-image other foreign)) (candidate (primary-candidate f 1 0)))
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index foreign key 0 1 0 0 context))
                     'invalid-argument :primary-fragment-owner)
    (is (primary-image-equal other-before (primary-image other foreign)))
    (primary-refusal f candidate
                     (lambda () (p:verifica-capienza-mutazione-indice index candidate key 0 1 #x80000000 0 context))
                     'invalid-argument :primary-fragment-prefix)
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index fragment key -1 1 0 0 context))
                     'invalid-argument :buffer-range)
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index fragment key 0 0 0 0 context))
                     'invalid-argument :primary-key-length)
    (setf (p::contesto-indice-busy context) t)
    (unwind-protect
         (progn
           (primary-refusal f fragment
                            (lambda () (p:verifica-capienza-mutazione-indice index fragment key 0 1 0 0 context))
                            'invalid-argument :primary-context-busy)
           (is (p::contesto-indice-busy context)))
      (setf (p::contesto-indice-busy context) nil))
    (setf (p::frammento-indice-exposure candidate) :retired)
    (primary-refusal f candidate
                     (lambda () (p:verifica-capienza-mutazione-indice index candidate key 0 1 0 0 context))
                     'invalid-argument :primary-fragment-retired)
    (s:congela-banco-slot (p::frammento-indice-bank fragment))
    (primary-refusal f fragment
                     (lambda () (p:verifica-capienza-mutazione-indice index fragment key 0 1 0 0 context))
                     'invalid-argument :index-slot-frozen)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-003-primary-mutation-preflight-canonical-fault-and-cleanup
  "Pre: salute guasta oppure controllo corrotto. Post: fail-stop canonico e contesto sempre libero."
  (dolist (fault '(:index :bank :control))
    (let* ((f (primary-fixture)) (fragment (primary-current f)) (index (primary-fixture-index f))
           (context (primary-fixture-writer f)) (key (primary-key 1)))
      (ecase fault
        (:index (p:invalida-indice-primario index))
        (:bank (s:invalida-banco-slot (p::frammento-indice-bank fragment)))
        (:control (setf (aref (p::frammento-indice-controls fragment) 0) 253)))
      (is (handler-case
              (progn (p:verifica-capienza-mutazione-indice index fragment key 0 1 0 0 context) nil)
            (invariant-violation (condition)
              (is (eq (error-reason condition)
                      (ecase fault (:index :primary-index-faulted) (:bank :primary-fragment-faulted)
                                   (:control :primary-control-corrupt))))
              t)))
      (is (eq :faulted (p::indice-primario-health index)))
      (is (not (p::contesto-indice-busy context))))))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-IDX-006
(deftest test-REQ-IDX-005-primary-manual-rebuild-compacts-and-publishes-current-root
  "Pre: sorgente con byte morti e copie vive verificate. Post: nuova root, arena compatta, fonte frozen."
  (let* ((f (primary-fixture)) (source (primary-current f)) (index (primary-fixture-index f))
         (old-root (p::indice-primario-root index)) (dead (primary-key 0 0 0))
         (a (primary-key 1 1)) (b (primary-key 2 2)))
    (primary-put f dead 1 0 0)
    (let ((expected-a (primary-put f a 2 0 1)) (expected-b (primary-put f b 3 0 2)))
      (is (primary-delete f dead 0 0))
      (let ((candidate (primary-candidate f 0 0 4)))
        (primary-copy-live f candidate b 0 2)
        (primary-copy-live f candidate a 0 1)
        (let ((plan (primary-plan f source candidate)))
          (is (eq old-root (p::indice-primario-root index)))
          (is (eq source (primary-current f)))
          (is (eq :building (p::frammento-indice-exposure candidate)))
          (is (eq :writable (s::banco-slot-state (p::frammento-indice-bank source))))
          (is (null (p:pubblica-directory-indice plan)))
          (is (eq :published (p::pubblicazione-indice-state plan))))
        (is (not (eq old-root (p::indice-primario-root index))))
        (is (eq source (aref (p::root-indice-directory old-root) 0)))
        (is (= 1 (p::root-indice-generation (p::indice-primario-root index))))
        (is (eq candidate (primary-current f)))
        (is (= 4 (p::frammento-indice-used candidate)))
        (is (eq :retired (p::frammento-indice-exposure source)))
        (is (eq :frozen (s::banco-slot-state (p::frammento-indice-bank source))))
        (primary-live f a 0 1 expected-a 2)
        (primary-live f b 0 2 expected-b 0)
        (primary-no-output f dead 0 0 :absent)
        (primary-refusal f source (lambda () (primary-put f a 4 0 1 :fragment source))
                         'invalid-argument :primary-fragment-retired)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-primary-manual-split-routes-msb-prefixes
  "Pre: copie manuali nei figli ordinati. Post: raddoppio directory, prefissi MSB e payload integri."
  (let* ((f (primary-fixture)) (source (primary-current f)) (index (primary-fixture-index f))
         (left-key (primary-key 1 2)) (right-key (primary-key 3 4))
         (left (primary-candidate f 1 0)) (right (primary-candidate f 1 1))
         (expected-left (primary-put f left-key 1 #x7fffffff 3))
         (expected-right (primary-put f right-key 2 #x80000000 4))
         (old (p::indice-primario-root index)))
    (primary-copy-live f left left-key #x7fffffff 3)
    (primary-copy-live f right right-key #x80000000 4)
    (is (null (p:pubblica-directory-indice (primary-plan f source left right))))
    (let* ((root (p::indice-primario-root index)) (directory (p::root-indice-directory root)))
      (is (= 1 (p::root-indice-depth root) (p::root-indice-generation root)))
      (is (= 2 (length directory)))
      (is (eq left (aref directory 0)))
      (is (eq right (aref directory 1)))
      (is (= 1 (length (p::root-indice-directory old)))))
    (primary-live f left-key #x7fffffff 3 expected-left 0)
    (primary-live f right-key #x80000000 4 expected-right 0)
    (is (eq left (primary-current f 0)))
    (is (eq right (primary-current f #xffffffff)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-primary-shallow-split-no-doubling-and-unrelated-mutable
  "Pre: profondita locali diverse. Post: split d<G senza crescita; frammenti estranei modificabili."
  (let* ((f (primary-fixture)) (index (primary-fixture-index f)) (source (primary-current f))
         (left (primary-candidate f 1 0)) (right (primary-candidate f 1 1)))
    (is (null (p:pubblica-directory-indice (primary-plan f source left right))))
    (let ((ll (primary-candidate f 2 0)) (lr (primary-candidate f 2 1)))
      (is (null (p:pubblica-directory-indice (primary-plan f left ll lr))))
      (let* ((old (p::indice-primario-root index))
             (rl (primary-candidate f 2 2)) (rr (primary-candidate f 2 3)))
        (is (eq right (aref (p::root-indice-directory old) 2)))
        (is (eq right (aref (p::root-indice-directory old) 3)))
        (is (null (p:pubblica-directory-indice (primary-plan f right rl rr))))
        (let ((root (p::indice-primario-root index)))
          (is (= 2 (p::root-indice-depth root)))
          (is (= 4 (length (p::root-indice-directory root))))
          (is (equalp (vector ll lr rl rr) (p::root-indice-directory root))))
        (is (eq :writable (s::banco-slot-state (p::frammento-indice-bank ll))))
        (is (eq :writable (s::banco-slot-state (p::frammento-indice-bank lr))))
        (let* ((key (primary-key 9)) (expected (primary-put f key 1 0 9)))
          (primary-put f key 2 0 9)
          (setf (aref expected 0) 2)
          (primary-live f key 0 9 expected 0)
          (is (primary-delete f key 0 9)))))))

;;; REQ: REQ-IDX-007 REQ-IDX-005
(deftest test-REQ-IDX-007-primary-stale-plan-after-source-update-no-freeze
  "Pre: piano preparato poi update del sorgente. Post: rifiuto prima del freeze, versione nuova viva."
  (let* ((f (primary-fixture)) (source (primary-current f)) (key (primary-key 1))
         (candidate (primary-candidate f 0 0)))
    (primary-put f key 1 0 1)
    (primary-copy-live f candidate key 0 1)
    (let* ((plan (primary-plan f source candidate)) (expected (primary-put f key 2 0 1))
           (candidate-before (primary-image f candidate)))
      (primary-refusal f source (lambda () (p:pubblica-directory-indice plan))
                       'invalid-argument :primary-directory-stale-plan)
      (is (primary-image-equal candidate-before (primary-image f candidate)))
      (is (eq :prepared (p::pubblicazione-indice-state plan)))
      (is (eq :writable (s::banco-slot-state (p::frammento-indice-bank source))))
      (primary-live f key 0 1 expected 0))))

;;; REQ: REQ-IDX-007 REQ-IDX-005
(deftest test-REQ-IDX-007-primary-stale-plan-after-candidate-update-and-arena-growth
  "Pre: piano preparato poi mutazione del candidato. Post: qualsiasi revisione invalida il piano."
  (dolist (operation '(:update :grow))
    (let* ((f (primary-fixture)) (source (primary-current f)) (key (primary-key 1))
           (candidate (primary-candidate f 0 0)))
      (primary-put f key 1 0 1)
      (primary-copy-live f candidate key 0 1)
      (let ((plan (primary-plan f source candidate)))
        (ecase operation
          (:update (primary-put f key 2 0 1 :fragment candidate))
          (:grow (is (null (p:estendi-arena-indice
                           (primary-fixture-index f) candidate 512 +primary-test-budget+)))))
        (let ((candidate-before (primary-image f candidate)))
          (primary-refusal f source (lambda () (p:pubblica-directory-indice plan))
                           'invalid-argument :primary-directory-stale-plan)
          (is (primary-image-equal candidate-before (primary-image f candidate))))
        (is (eq :building (p::frammento-indice-exposure candidate)))
        (primary-live f key 0 1 (primary-payload key 1) 0)))))

;;; REQ: REQ-IDX-007 REQ-IDX-005
(deftest test-REQ-IDX-007-primary-two-plans-old-root-and-consumed-plan-refused
  "Pre: due piani per la stessa root. Post: uno solo pubblica; piano vecchio e consumato rifiutati."
  (let* ((f (primary-fixture)) (source (primary-current f))
         (a (primary-candidate f 0 0)) (b (primary-candidate f 0 0))
         (plan-a (primary-plan f source a)) (plan-b (primary-plan f source b)))
    (is (null (p:pubblica-directory-indice plan-a)))
    (dolist (plan (list plan-a plan-b))
      (primary-refusal f a (lambda () (p:pubblica-directory-indice plan))
                       'invalid-argument :primary-directory-stale-plan))
    (is (eq :published (p::pubblicazione-indice-state plan-a)))
    (is (eq :prepared (p::pubblicazione-indice-state plan-b)))
    (is (eq :building (p::frammento-indice-exposure b)))
    (is (eq :writable (s::banco-slot-state (p::frammento-indice-bank a))))
    (primary-refusal f a (lambda () (primary-plan f source b))
                     'invalid-argument :primary-directory-source)))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(deftest test-REQ-IDX-007-primary-directory-candidates-and-exact-budget
  "Pre: candidati vuoti e sorgente canonico. Post: geometria/count/owner/budget verificati prima."
  (let* ((f (primary-fixture)) (source (primary-current f))
         (left (primary-candidate f 1 0)) (right (primary-candidate f 1 1))
         (other (primary-fixture)) (foreign (primary-candidate other 0 0)))
    (primary-refusal f source (lambda () (primary-plan f source right left))
                     'invalid-argument :primary-directory-replacement)
    (primary-refusal f source (lambda () (primary-plan f source foreign))
                     'invalid-argument :primary-fragment-owner)
    (primary-refusal f source (lambda () (primary-plan f source source))
                     'invalid-argument :primary-directory-replacement)
    (let ((budget (primary-plan-budget f left right)))
      (primary-refusal f source
                       (lambda () (p:prepara-directory-indice
                                   (primary-fixture-index f) source left (1- budget) right))
                       'resource-exhausted :primary-directory-transient-budget)
      (is (typep (p:prepara-directory-indice
                  (primary-fixture-index f) source left budget right) 'p:pubblicazione-indice)))
    (primary-put f (primary-key 1) 1 0 1)
    (primary-refusal f source (lambda () (primary-plan f source left right))
                     'invalid-argument :primary-directory-plan))
  (let* ((f (primary-fixture :directory-budget 8)) (source (primary-current f))
         (left (primary-candidate f 1 0)) (right (primary-candidate f 1 1)))
    (primary-refusal f source (lambda () (primary-plan f source left right))
                     'resource-exhausted :primary-directory-memory-budget)))

;;; REQ: REQ-IDX-004 REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-004-primary-relocation-message-survives-rebuild-not-new-version
  "Pre: messaggio con vecchio offset arena. Post: lookup corrente, location sola; stale/miss no-op."
  (let* ((f (primary-fixture)) (source (primary-current f)) (index (primary-fixture-index f))
         (dead (primary-key 0 0 0)) (key (primary-key 1 2)) (candidate (primary-candidate f 0 0 2)))
    (primary-put f dead 1 0 0)
    (let* ((payload (primary-put f key 2 0 1))
           (expected (primary-live f key 0 1 payload 3))
           (replacement (copy-seq expected)))
      (setf (aref replacement 1) #xa500000800)
      (is (primary-delete f dead 0 0))
      (primary-copy-live f candidate key 0 1)
      (is (null (p:pubblica-directory-indice (primary-plan f source candidate))))
      (primary-live f key 0 1 payload 0)
      (flet ((relocate (lookup original copy)
               (p:riloca-chiave-indice index lookup 0 (length lookup) 0 1 original copy
                                      (primary-fixture-writer f))))
        (is (relocate key expected replacement))
        (let ((current (primary-live f key 0 1 replacement 0))
              (before (primary-image f candidate)))
          (is (not (relocate key expected replacement)))
          (is (relocate key current replacement))
          (is (not (relocate (primary-key 9 9) expected replacement)))
          (is (primary-image-equal before (primary-image f candidate))))
        (primary-put f key 3 0 1)
        (let ((before (primary-image f candidate)))
          (is (not (relocate key replacement expected)))
          (is (primary-image-equal before (primary-image f candidate))))
        (let ((bad (copy-seq replacement)))
          (incf (aref bad 0))
          (primary-refusal f candidate (lambda () (relocate key expected bad))
                           'invalid-argument :primary-relocation-content))))))

;;; REQ: REQ-IDX-007 REQ-IDX-003
(deftest test-REQ-IDX-007-primary-root-changes-hit-miss-and-common-budget
  "Pre: FI dopo sondaggio prima della conferma. Post: hit/miss ripetuti, otto crediti complessivi."
  (dolist (present '(nil t))
    (dolist (changes '(1 8))
      (let* ((f (primary-fixture)) (key (primary-key 1)) (calls 0) (swaps 0)
             (expected (primary-payload key 1)))
        (when present (primary-put f key 1 0 1))
        (fill (primary-fixture-output f) +primary-sentinel+)
        (primary-with-probe-fi
         (lambda (result)
           (is (if present (>= result 0) (= result -1)))
           (incf calls)
           (is (every (lambda (word) (= word +primary-sentinel+)) (primary-fixture-output f)))
           (when (< swaps changes)
             (let* ((source (primary-current f)) (candidate (primary-candidate f 0 0)))
               ;; La copia e costruita dal payload noto: nessun lookup ricorsivo nel punto FI.
               (when present (primary-put f key 1 0 1 :fragment candidate :source expected))
               (is (null (p:pubblica-directory-indice (primary-plan f source candidate))))
               (incf swaps))))
         (lambda ()
           (is (eq (if (= changes 1) (if present :live :absent) :retry-limit)
                   (primary-read f key 0 1)))))
        (is (= calls (if (= changes 1) 2 (if present 4 8))))
        (is (= swaps (if (= changes 1) 1 (if present 4 8))))
        (is (= (p::contesto-indice-remaining (primary-fixture-reader f))
               (if (= changes 1) (if present 5 7) 0)))
        (if (and present (= changes 1))
            (primary-check-payload (primary-fixture-output f) expected 0)
            (is (every (lambda (word) (= word +primary-sentinel+)) (primary-fixture-output f))))))
  t))

;;; REQ: REQ-IDX-007 REQ-IDX-003
(deftest test-REQ-IDX-007-primary-final-confirmation-exhausted-no-restart
  "La conferma finale fallita a credito zero termina senza un nuovo probe o copia output."
  (let* ((f (primary-fixture)) (source (primary-current f))
         (candidate (primary-candidate f 0 0)) (calls 0))
    (dotimes (i 8)
      (primary-put f (primary-key i) (1+ i) 0 4)
      (primary-put f (primary-key i) (1+ i) 0 4 :fragment candidate))
    (let ((plan (primary-plan f source candidate)))
      (primary-with-probe-fi
       (lambda (result)
         (is (>= result 0)) (incf calls)
         (is (zerop (p::contesto-indice-remaining (primary-fixture-reader f))))
         (is (null (p:pubblica-directory-indice plan))))
       (lambda () (primary-no-output f (primary-key 7) 0 4 :retry-limit)))
      (is (= calls 1))
      (is (zerop (p::contesto-indice-remaining (primary-fixture-reader f)))))))
