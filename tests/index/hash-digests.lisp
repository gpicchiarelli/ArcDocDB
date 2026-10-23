;;;; Mappe hash: integrazione C4, nessuna esecuzione al caricamento.
;;;; OWNER: runner seriale; fixture seeded, writer, mappe e scratch sempre privati.
;;;; SHARED: le sole FI di funzioni sono ripristinate con UNWIND-PROTECT.
;;;; Il kernel XXH64 ha oracoli separati; qui si verifica il contratto dell'indice.
(in-package #:arcdocdb.index.primary.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (t t &key (:capacity integer) (:arena-bytes integer))
                         primary-fixture) hash-map-fixture))
(defun hash-map-fixture (seed-high seed-low &key (capacity 32) (arena-bytes 256))
  "Pre: seed esplicito della fixture. Post: harness esistente con indice seeded e risorse private."
  (%make-primary-fixture
   (p:crea-indice-primario :capacity capacity :arena-bytes arena-bytes :max-depth 4
                         :directory-budget-bytes +primary-test-budget+
                         :fragment-budget-bytes +primary-test-budget+
                         :hash-seed-high seed-high :hash-seed-low seed-low)
   (p:crea-contesto-indice) (p:crea-contesto-indice)
   (make-array 5 :element-type '(unsigned-byte 64) :initial-element +primary-sentinel+)))

;;; REQ: REQ-IDX-005
(declaim (ftype (function (integer) (values p::digests-frammento p::digests-frammento &optional))
                hash-map-arrays))
(defun hash-map-arrays (capacity)
  "Pre: C noto. Post: due simple array u32 distinti, sentinel diversi anche per slot."
  (let ((highs (make-array capacity :element-type '(unsigned-byte 32)))
        (lows (make-array capacity :element-type '(unsigned-byte 32))))
    (dotimes (slot capacity)
      (setf (aref highs slot) (+ #xa5a50000 slot) (aref lows slot) (+ #x5a5a0000 slot)))
    (values highs lows)))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture octets u64) list) hash-map-put))
(defun hash-map-put (fixture key csn)
  "Pre: writer esclusivo. Post: digest pubblico a due u32, writer e lookup reali con lo stesso seed."
  (let* ((index (primary-fixture-index fixture))
         (digest (multiple-value-list (p:digest-chiave-indice index key 0 (length key))))
         (reference (multiple-value-list
                     (arcdocdb.hash64:xxh64 key 0 (length key)
                                          (p::indice-primario-seed-high index)
                                          (p::indice-primario-seed-low index)))))
    (is (= 2 (length digest)))
    (is (every (lambda (word) (typep word 'u32)) digest))
    (is (equal digest reference))
    (let ((payload (primary-put fixture key csn (first digest) (second digest))))
      (primary-live fixture key (first digest) (second digest) payload)
      (list key (first digest) (second digest) payload))))

;;; REQ: REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (p:frammento-indice list) list) hash-map-physical-slots))
(defun hash-map-physical-slots (source entries)
  "Oracolo prima delle mappe: scansione indipendente del banco sotto writer, senza probe del prodotto.
Ogni record contiene SLOT/OFFSET/SIZE/ENTRY; le chiavi attese provengono dal writer, mai dalla mappa."
  (let ((words (s::banco-slot-words (p::frammento-indice-bank source)))
        (arena (p::frammento-indice-arena source)) (records nil))
    (dotimes (slot (length (p::frammento-indice-controls source)))
      (let ((base (* slot 5)))
        (is (evenp (aref words (+ base 3))))
        (when (plusp (aref words base))
          (let* ((metadata (aref words (+ base 2)))
                 (offset (ldb (byte 32 0) metadata)) (size (ldb (byte 16 32) metadata))
                 (key (subseq arena offset (+ offset size)))
                 (entry (find key entries :key #'first :test #'equalp)))
            (is entry)
            (is (= (aref words base) (aref (fourth entry) 0)))
            (is (= (logand (third entry) 127)
                   (aref (p::frammento-indice-controls source) slot)))
            (push (list slot offset size entry) records)))))
    (is (= (length records) (length entries)))
    (is (= (length entries) (length (remove-duplicates (mapcar #'fourth records) :test #'eq))))
    (nreverse records)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice) list) hash-map-image))
(defun hash-map-image (fixture source)
  "Pre: fixture posseduta. Post: bytes, identita banco/controlli/directory, seed e contesti conservati."
  (let* ((index (primary-fixture-index fixture)) (root (p::indice-primario-root index)))
    (list (primary-image fixture source) (p::frammento-indice-bank source)
          (p::frammento-indice-controls source)
          (when root (copy-seq (p::root-indice-directory root)))
          (p::indice-primario-seed-high index) (p::indice-primario-seed-low index)
          (copy-seq (p::contesto-indice-words (primary-fixture-writer fixture)))
          (copy-seq (p::contesto-indice-words (primary-fixture-reader fixture)))
          (copy-seq (primary-fixture-output fixture)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (list list) boolean) hash-map-image-equal))
(defun hash-map-image-equal (before after)
  "Pre: due snapshot. Post: identita esplicite e tutti i valori, compresa revisione, uguali."
  (and (primary-image-equal (first before) (first after))
       (eq (second before) (second after)) (eq (third before) (third after))
       (every #'eq (fourth before) (fourth after)) (equalp (nthcdr 4 before) (nthcdr 4 after))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(declaim (ftype (function (symbol function function) t) hash-map-with-fi))
(defun hash-map-with-fi (symbol factory thunk)
  "Solo runner seriale: wrapper della funzione reale, ripristinato anche su rifiuti e guasti."
  (let ((original (symbol-function symbol)))
    (unwind-protect
         (progn (setf (symbol-function symbol) (funcall factory original)) (funcall thunk))
      (setf (symbol-function symbol) original))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(declaim (ftype (function (function function) t) hash-map-with-spies))
(defun hash-map-with-spies (observer thunk)
  "Pre: callback di osservazione. Post: campionamento/hash/verifica reali, valori multipli preservati."
  (labels ((visit (bindings)
             (if (null bindings) (funcall thunk)
                 (let ((kind (caar bindings)) (symbol (cdar bindings)))
                   (hash-map-with-fi
                    symbol (lambda (original)
                             (lambda (&rest arguments)
                               (funcall observer kind arguments)
                               (apply original arguments)))
                    (lambda () (visit (rest bindings))))))))
    (visit '((:sample . p::campiona-ricostruzione)
             (:hash . arcdocdb.hash64:xxh64) (:verify . p::verifica-digest-ricostruzione)))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(declaim (ftype (function (function symbol keyword) null) hash-map-error))
(defun hash-map-error (thunk type reason)
  "Pre: rifiuto atteso. Post: classe e reason esatte; nessun errore estraneo assorbito."
  (is (handler-case (progn (funcall thunk) nil)
        (arcdocdb-error (condition)
          (is (typep condition type)) (is (eq reason (error-reason condition))) t)))
  nil)

;;; REQ: REQ-IDX-005
(declaim (ftype (function (t) t) hash-map-output-image))
(defun hash-map-output-image (value)
  "Pre: output anche malformato. Post: copia dei valori, compresi array multidimensionali."
  (if (arrayp value)
      (list (array-dimensions value) (array-element-type value)
            (loop for i below (array-total-size value) collect (row-major-aref value i)))
      (copy-tree value)))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (primary-fixture p:frammento-indice t t t t keyword) null)
                hash-map-preflight-refusal))
(defun hash-map-preflight-refusal (fixture source highs lows seed-high seed-low reason)
  "Pre: rifiuto preflight. Post: zero campioni/hash/verifiche, mappe e indice interamente immutati."
  (let ((before (hash-map-image fixture source)) (h (hash-map-output-image highs))
        (l (hash-map-output-image lows)) (calls 0))
    (hash-map-with-spies
     (lambda (kind arguments) (declare (ignore kind arguments)) (incf calls))
     (lambda () (hash-map-error
                 (lambda () (p:calcola-digests-frammento (primary-fixture-index fixture)
                                                        source highs lows seed-high seed-low))
                 'invalid-argument reason)))
    (is (zerop calls)) (is (equalp h (hash-map-output-image highs)))
    (is (equalp l (hash-map-output-image lows)))
    (is (hash-map-image-equal before (hash-map-image fixture source))))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice list
                         p::digests-frammento p::digests-frammento) list) hash-map-calculate))
(defun hash-map-calculate (fixture source records highs lows)
  "Pre: slots attendibili gia acquisiti prima della mappa. Post: un pass C, due scratch distinti e 3 valori.
Ogni digest viene verificato allo slot originale prima di entrambe le scritture nella mappa privata."
  (let* ((index (primary-fixture-index fixture)) (before (hash-map-image fixture source))
         (h (copy-seq highs)) (l (copy-seq lows)) (seen 0) (hashed 0) (verified 0)
         (current nil) (words nil) (work nil) (phase nil)
         (seed-high (p::indice-primario-seed-high index)) (seed-low (p::indice-primario-seed-low index)))
    (let ((result
            (hash-map-with-spies
             (lambda (kind arguments)
               (ecase kind
                 (:sample
                  (is (eq source (first arguments))) (is (= seen (second arguments)))
                  (setf current (assoc seen records) phase :sample)
                  (is (= (aref h seen) (aref highs seen))) (is (= (aref l seen) (aref lows seen)))
                  (if words (is (eq words (third arguments))) (setf words (third arguments)))
                  (incf seen))
                 (:hash
                  (is current) (is (eq phase :sample))
                  (is (equal (list (second current) (+ (second current) (third current)) seed-high seed-low)
                             (rest arguments)))
                  (is (eq (p::frammento-indice-arena source) (first arguments)))
                  (setf phase :hash) (incf hashed))
                 (:verify
                  (is current) (is (eq phase :hash)) (is (eq source (first arguments)))
                  (is (= (first current) (second arguments)))
                  (is (equal (list (second (fourth current)) (third (fourth current)))
                             (subseq arguments 2 4)))
                  (is (eq words (fifth arguments)))
                  (if work (is (eq work (sixth arguments))) (setf work (sixth arguments)))
                  (is (= (aref h (first current)) (aref highs (first current))))
                  (is (= (aref l (first current)) (aref lows (first current))))
                  (setf phase :verify) (incf verified))))
             (lambda () (multiple-value-list
                         (p:calcola-digests-frammento index source highs lows seed-high seed-low))))))
      (is (= 3 (length result)))
      (is (equal (list (length highs) (length records) (reduce #'+ records :key #'third :initial-value 0))
                 result))
      (is (= seen (length highs))) (is (= hashed verified (length records)))
      (when records
        (is (typep words '(simple-array (unsigned-byte 64) (5))))
        (is (typep work '(simple-array (unsigned-byte 64) (5)))) (is (not (eq words work)))
        (dolist (shared (list (s::banco-slot-words (p::frammento-indice-bank source))
                              (p::contesto-indice-words (primary-fixture-writer fixture))
                              (p::contesto-indice-words (primary-fixture-reader fixture))
                              (primary-fixture-output fixture)))
          (is (not (eq words shared))) (is (not (eq work shared)))))
      (dotimes (slot (length highs))
        (let ((record (assoc slot records)))
          (is (= (aref highs slot) (if record (second (fourth record)) (aref h slot))))
          (is (= (aref lows slot) (if record (third (fourth record)) (aref l slot))))))
      (is (hash-map-image-equal before (hash-map-image fixture source)))
      result)))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice list
                         p::digests-frammento p::digests-frammento boolean) p:pubblicazione-indice)
                hash-map-rebuild))
(defun hash-map-rebuild (fixture source records highs lows split)
  "Pre: mappe gia scritte e verificate. Post: rebuild/split vero; sola pubblicazione esplicita finale."
  (let* ((index (primary-fixture-index fixture)) (old (p::indice-primario-root index))
         (h (copy-seq highs)) (l (copy-seq lows))
         (result (multiple-value-list
                  (p:ricostruisci-frammento-indice index source highs lows +primary-test-budget+ :split-p split)))
         (plan (first result)))
    (is (= 5 (length result))) (is (typep plan 'p:pubblicazione-indice))
    (is (= (second result) (length highs)))
    (is (= (third result) (reduce #'+ records :key #'third :initial-value 0)))
    (is (eq old (p::indice-primario-root index)))
    (is (equalp h highs)) (is (equalp l lows))
    (is (eq :published (p::frammento-indice-exposure source)))
    (is (eq :writable (s::banco-slot-state (p::frammento-indice-bank source))))
    (is (null (p:pubblica-directory-indice plan)))
    (is (eq :retired (p::frammento-indice-exposure source)))
    (is (eq :frozen (s::banco-slot-state (p::frammento-indice-bank source))))
    (is (eq (p::pubblicazione-indice-replacement plan) (p::indice-primario-root index)))
    plan))

;;; REQ: REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (primary-fixture) list) hash-map-entries))
(defun hash-map-entries (fixture)
  "Fixture bounded: chiavi scelte prima del writer per alternare gruppi fisici 16/0 e figli dello split."
  (let ((index (primary-fixture-index fixture)) (entries nil))
    (dolist (spec '((16 1) (0 0) (16 0) (0 1)))
      (let ((key (loop for byte below 256
                       for candidate = (primary-key #xd1 byte 0 #xff (+ 1 (length entries)))
                       for digest = (multiple-value-list
                                     (p:digest-chiave-indice index candidate 0 (length candidate)))
                       when (and (= (first spec) (if (logbitp 11 (second digest)) 16 0))
                                 (= (second spec) (if (logbitp 31 (first digest)) 1 0)))
                         return candidate)))
        (is key)
        (setf entries (append entries (list (hash-map-put fixture key (+ 11 (length entries))))))))
    entries))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(declaim (ftype (function (primary-fixture p:frammento-indice p::digests-frammento
                         p::digests-frammento keyword &optional boolean) null) hash-map-fault))
(defun hash-map-fault (fixture source highs lows reason &optional preflight)
  "Pre: FI gia applicata. Post: guasto terminale prima del ritorno; solo salute puo cambiare.
Mappe private potenzialmente parziali dopo scansione: scartarle su qualsiasi fallimento."
  (let* ((index (primary-fixture-index fixture)) (before (hash-map-image fixture source))
         (h (copy-seq highs)) (l (copy-seq lows)) (calls 0))
    (hash-map-with-spies
     (lambda (kind arguments) (declare (ignore kind arguments)) (incf calls))
     (lambda () (hash-map-error
                 (lambda () (p:calcola-digests-frammento index source highs lows
                                                        (or (p::indice-primario-seed-high index) 0)
                                                        (or (p::indice-primario-seed-low index) 0)))
                 'invariant-violation reason)))
    (is (eq :faulted (p::indice-primario-health index)))
    (when preflight (is (zerop calls)) (is (equalp h highs)) (is (equalp l lows)))
    (let ((after (hash-map-image fixture source)))
      (setf (nth 3 (first before)) :health (nth 3 (first after)) :health
            (nth 8 (first before)) :health (nth 8 (first after)) :health)
      (is (hash-map-image-equal before after)))
    (setf h (copy-seq highs) l (copy-seq lows))
    (hash-map-error (lambda () (p:calcola-digests-frammento index source highs lows 0 0))
                    'invariant-violation :primary-index-faulted)
    (is (equalp h highs)) (is (equalp l lows)))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-IDX-007
(deftest TEST-REQ-IDX-005-HASH-MAP-PHYSICAL-SLOTS
  (dolist (seed '(0 #xffffffff))
    (let* ((f (hash-map-fixture seed seed)) (index (primary-fixture-index f))
           (entries (hash-map-entries f)) (source (primary-current f))
           (records (hash-map-physical-slots source entries)))
      (is (loop for entry in entries for ordinal from 0
                thereis (/= ordinal (first (find entry records :key #'fourth :test #'eq)))))
      (is (some (lambda (entry) (/= (second entry) (third entry))) entries))
      (is (some (lambda (record) (plusp (second record))) records))
      (dolist (split '(nil t))
        (setf source (primary-current f) records (hash-map-physical-slots source entries))
        (multiple-value-bind (highs lows) (hash-map-arrays 32)
          (hash-map-calculate f source records highs lows)
          (hash-map-rebuild f source records highs lows split))
        (dolist (entry entries)
          (primary-live f (first entry) (second entry) (third entry) (fourth entry))))
      (let* ((root (p::indice-primario-root index)) (directory (p::root-indice-directory root))
             (live 0) (bytes 0))
        (is (= 1 (p::root-indice-depth root)))
        (is (not (eq (aref directory 0) (aref directory 1))))
        (dotimes (prefix 2)
          (let* ((child (aref directory prefix))
                 (subset (remove-if-not (lambda (entry) (= prefix (ash (second entry) -31))) entries))
                 (child-records (hash-map-physical-slots child subset)))
            (is (= prefix (p::frammento-indice-prefix child)))
            (is (= 2 (length child-records)))
            (multiple-value-bind (highs lows) (hash-map-arrays 32)
              (let ((result (hash-map-calculate f child child-records highs lows)))
                (incf live (second result)) (incf bytes (third result))))))
        (is (= 4 live)) (is (= 20 bytes)))
      ;; Il writer dopo lo split usa ancora il seed posseduto per hash e lookup.
      (let* ((entry (first entries)) (updated (hash-map-put f (first entry) 99)))
        (is (equal (subseq entry 1 3) (subseq updated 1 3)))
        (is (= seed (p::indice-primario-seed-high index) (p::indice-primario-seed-low index)))))))

;;; REQ: REQ-IDX-005 REQ-IDX-006
(deftest test-REQ-IDX-005-hash-map-nonlive-sentinels-and-exact-counts
  (let* ((f (hash-map-fixture 0 0)) (entries (hash-map-entries f))
         (source (primary-current f)) (dead (second entries)))
    (is (primary-delete f (first dead) (second dead) (third dead)))
    (is (find 254 (p::frammento-indice-controls source)))
    (is (find 255 (p::frammento-indice-controls source)))
    (let* ((live (remove dead entries :test #'eq)) (records (hash-map-physical-slots source live)))
      (is (= 20 (p::frammento-indice-used source)))
      (multiple-value-bind (highs lows) (hash-map-arrays 32)
        (is (equal '(32 3 15) (hash-map-calculate f source records highs lows))))
      (primary-no-output f (first dead) (second dead) (third dead) :absent))))

;;; REQ: REQ-IDX-001 REQ-IDX-005
(deftest test-REQ-IDX-005-hash-map-output-arity-empty-and-unconfigured
  (let* ((f (hash-map-fixture #xffffffff 0)) (source (primary-current f)))
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (is (equal '(32 0 0) (hash-map-calculate f source nil highs lows)))))
  (let* ((f (primary-fixture)) (source (primary-current f))
         (key (primary-key 0 #xff)) (index (primary-fixture-index f))
         (payload (primary-put f key 1 0 7)))
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-preflight-refusal f source highs lows 0 0 :primary-hash-unconfigured))
    (primary-refusal f source (lambda () (p:digest-chiave-indice index key 0 2))
                     'invalid-argument :primary-hash-unconfigured)
    (primary-live f key 0 7 payload)))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-IDX-005-hash-map-seed-constructor-and-immutability
  (is (not (fboundp '(setf p::indice-primario-seed-high))))
  (is (not (fboundp '(setf p::indice-primario-seed-low))))
  (dolist (pair '((nil 0) (0 nil) (nil #xffffffff) (#xffffffff nil)
                  (-1 0) (0 -1) (#x100000000 0) (0 #x100000000)
                  (1.0 0) (0 1.0) (:bad 0) (0 :bad)))
    (let ((factories 0))
      (hash-map-with-fi
       'p:crea-frammento-indice
       (lambda (original) (lambda (&rest args) (incf factories) (apply original args)))
       (lambda () (hash-map-error (lambda () (hash-map-fixture (first pair) (second pair)))
                                  'invalid-argument :primary-hash-seed-configuration)))
      (is (zerop factories))))
  (dolist (pair '((0 0) (#xffffffff #xffffffff) (0 #xffffffff) (#xffffffff 0)))
    (let* ((f (hash-map-fixture (first pair) (second pair)))
           (index (primary-fixture-index f)) (key (primary-key 1 0 #xff))
           (entry (hash-map-put f key 7)) (source (primary-current f)))
      (dotimes (repeat 3)
        (is (equal (subseq entry 1 3) (multiple-value-list (p:digest-chiave-indice index key 0 3)))))
      (is (= (first pair) (p::indice-primario-seed-high index)))
      (is (= (second pair) (p::indice-primario-seed-low index)))
      (p:invalida-indice-primario index)
      (primary-refusal f source (lambda () (p:digest-chiave-indice index key 0 3))
                       'invariant-violation :primary-index-faulted)
      (multiple-value-bind (highs lows) (hash-map-arrays 32)
        (hash-map-fault f source highs lows :primary-index-faulted t))))
  ;; FI del costruttore privato: solo le due coppie interne incoerenti richieste.
  (dolist (pair '((nil 0) (0 nil)))
    (dolist (api '(:digest :map))
      (let* ((index (p::%make-indice-primario 32 4 +primary-test-budget+ +primary-test-budget+
                                            (first pair) (second pair)))
             (source (p:crea-frammento-indice index :arena-bytes 8)))
        (setf (p::frammento-indice-exposure source) :published
              (p::indice-primario-root index) (p::%make-root-indice 0 0 (vector source)))
        (let ((f (%make-primary-fixture index (p:crea-contesto-indice) (p:crea-contesto-indice)
                                        (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))))
          (if (eq api :map)
              (multiple-value-bind (highs lows) (hash-map-arrays 32)
                (hash-map-fault f source highs lows :primary-hash-seed-corrupt t))
              (progn
                (hash-map-error (lambda () (p:digest-chiave-indice index (primary-key 1) 0 1))
                                'invariant-violation :primary-hash-seed-corrupt)
                (is (eq :faulted (p::indice-primario-health index)))
                (hash-map-error (lambda () (p:digest-chiave-indice index (primary-key 1) 0 1))
                                'invariant-violation :primary-index-faulted))))))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(deftest test-REQ-IDX-005-hash-map-output-types-preflight
  (let* ((f (hash-map-fixture 0 0)) (entry (hash-map-put f (primary-key 1 2) 1))
         (source (primary-current f)))
    (dolist (bad (list nil 32 :bad '(0 0) (make-array 32 :initial-element 0)
                      (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
                      (make-array 32 :element-type '(unsigned-byte 64) :initial-element 0)
                      (make-array '(4 8) :element-type '(unsigned-byte 32) :initial-element 0)
                      (make-array 32 :element-type '(unsigned-byte 32) :adjustable t :initial-element 0)
                      (make-array 32 :element-type '(unsigned-byte 32) :fill-pointer 32 :initial-element 0)))
      (multiple-value-bind (highs lows) (hash-map-arrays 32)
        (hash-map-preflight-refusal f source bad lows 0 0 :primary-hash-arrays)
        (hash-map-preflight-refusal f source highs bad 0 0 :primary-hash-arrays)))
    (primary-live f (first entry) (second entry) (third entry) (fourth entry))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(deftest test-REQ-IDX-005-hash-map-output-lengths-preflight
  (let* ((f (hash-map-fixture 0 0)) (source (primary-current f)))
    (hash-map-put f (primary-key 2 3) 1)
    (dolist (size '(0 31 33))
      (multiple-value-bind (bad unused) (hash-map-arrays size)
        (declare (ignore unused))
        (multiple-value-bind (highs lows) (hash-map-arrays 32)
          (hash-map-preflight-refusal f source bad lows 0 0 :primary-hash-arrays)
          (hash-map-preflight-refusal f source highs bad 0 0 :primary-hash-arrays))))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(deftest test-REQ-IDX-005-hash-map-output-alias-preflight
  (let* ((f (hash-map-fixture 0 0)) (source (primary-current f)))
    (hash-map-put f (primary-key 3 4) 1)
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-preflight-refusal f source highs highs 0 0 :primary-hash-arrays)
      (hash-map-preflight-refusal f source lows lows 0 0 :primary-hash-arrays)
      (let ((alias (make-array 32 :element-type '(unsigned-byte 32) :displaced-to highs)))
        (hash-map-preflight-refusal f source highs alias 0 0 :primary-hash-arrays)
        (hash-map-preflight-refusal f source alias lows 0 0 :primary-hash-arrays)))))

;;; REQ: REQ-IDX-005 REQ-AFF-008
(deftest test-REQ-IDX-005-hash-map-invalid-seed-types-preflight
  (let* ((f (hash-map-fixture 0 0)) (source (primary-current f)))
    (hash-map-put f (primary-key 4 5) 1)
    (dolist (bad '(-1 #x100000000 0.0 1/2 nil :bad "0"))
      (multiple-value-bind (highs lows) (hash-map-arrays 32)
        (hash-map-preflight-refusal f source highs lows bad 0 :primary-hash-seed)
        (hash-map-preflight-refusal f source highs lows 0 bad :primary-hash-seed)))
    ;; I tipi degli array e poi del seed precedono perfino il rifiuto unconfigured.
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-preflight-refusal f source highs lows -1 0 :primary-hash-seed))
    (let* ((raw (primary-fixture)) (raw-source (primary-current raw)))
      (multiple-value-bind (highs lows) (hash-map-arrays 32)
        (hash-map-preflight-refusal raw raw-source nil lows -1 0 :primary-hash-arrays)
        (hash-map-preflight-refusal raw raw-source highs lows -1 0 :primary-hash-seed)))))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-IDX-007
(deftest TEST-REQ-IDX-005-HASH-MAP-SEED-MISMATCH
  ;; Anche sorgente vuoto e collisioni non possono autorizzare un seed differente.
  ;; Il nuovo contratto esige zero scritture: qui le mappe NON sono parziali.
  (dolist (seed '((0 0) (#xffffffff #xffffffff) (#x12345678 #x9abcdef0)))
    (dolist (populated '(nil t))
      (let* ((f (hash-map-fixture (first seed) (second seed))) (source (primary-current f))
             (entry (when populated (hash-map-put f (primary-key 5 0 #xff 6) 1))))
        (dolist (wrong (list (list (logxor 1 (first seed)) (second seed))
                            (list (first seed) (logxor 1 (second seed)))
                            (list (logxor 1 (first seed)) (logxor 1 (second seed)))))
          (multiple-value-bind (highs lows) (hash-map-arrays 32)
            (hash-map-preflight-refusal f source highs lows (first wrong) (second wrong)
                                        :primary-hash-seed-mismatch)))
        (is (eq :open (p::indice-primario-health (primary-fixture-index f))))
        (is (eq :open (s::banco-slot-health (p::frammento-indice-bank source))))
        (when entry (primary-live f (first entry) (second entry) (third entry) (fourth entry)))
        (multiple-value-bind (highs lows) (hash-map-arrays 32)
          (hash-map-calculate f source (hash-map-physical-slots source (if entry (list entry) nil))
                              highs lows))))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-hash-map-stale-source
  (let* ((f (hash-map-fixture 0 0)) (entry (hash-map-put f (primary-key 6 7) 1))
         (source (primary-current f)) (records (hash-map-physical-slots source (list entry))))
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-calculate f source records highs lows)
      (hash-map-rebuild f source records highs lows nil))
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-preflight-refusal f source highs lows 0 0 :primary-directory-source))
    (primary-live f (first entry) (second entry) (third entry) (fourth entry))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-hash-map-building-source
  (let* ((f (hash-map-fixture 0 0)) (entry (hash-map-put f (primary-key 7 8) 1))
         (source (primary-candidate f 0 0)) (current (primary-current f))
         (before (hash-map-image f current)))
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-preflight-refusal f source highs lows 0 0 :primary-directory-source))
    (is (hash-map-image-equal before (hash-map-image f current)))
    (primary-live f (first entry) (second entry) (third entry) (fourth entry))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(deftest test-REQ-IDX-005-hash-map-foreign-source
  (let* ((f (hash-map-fixture 0 0)) (other (hash-map-fixture 0 0))
         (entry (hash-map-put f (primary-key 8 9) 1))
         (foreign (primary-current other)) (current (primary-current f))
         (own-before (hash-map-image f current)) (other-before (hash-map-image other foreign)))
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-preflight-refusal f foreign highs lows 0 0 :primary-fragment-owner))
    (is (hash-map-image-equal own-before (hash-map-image f current)))
    (is (hash-map-image-equal other-before (hash-map-image other foreign)))
    (primary-live f (first entry) (second entry) (third entry) (fourth entry))))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(deftest test-REQ-IDX-005-hash-map-canonical-root-and-bank-guards
  (dolist (scenario '(:noncanonical :frozen :faulted))
    (let* ((f (hash-map-fixture 0 0)) (source (primary-current f)))
      (hash-map-put f (primary-key 9 10) 1)
      (ecase scenario
        (:noncanonical
         (setf source (primary-candidate f 0 0) (p::frammento-indice-exposure source) :published))
        (:frozen (s:congela-banco-slot (p::frammento-indice-bank source)))
        (:faulted (s:invalida-banco-slot (p::frammento-indice-bank source))))
      (multiple-value-bind (highs lows) (hash-map-arrays 32)
        (if (eq scenario :faulted)
            (hash-map-fault f source highs lows :primary-fragment-faulted t)
            (hash-map-preflight-refusal f source highs lows 0 0
                                        (if (eq scenario :frozen) :index-slot-frozen :primary-directory-source)))))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-hash-map-corrupt-bank-faults-immediately
  (dolist (scenario '(:payload :sequence :odd :control :live-empty :empty-live))
    (let* ((f (hash-map-fixture 0 0 :capacity 16))
           (entry (hash-map-put f (primary-key 10 11) 1)) (source (primary-current f))
           (slot (first (first (hash-map-physical-slots source (list entry)))))
           (words (s::banco-slot-words (p::frammento-indice-bank source)))
           (controls (p::frammento-indice-controls source)))
      (ecase scenario
        (:payload (setf (aref words (* slot 5)) 0))
        (:sequence (setf (aref words (+ (* slot 5) 3)) (expt 2 62)))
        (:odd (setf (aref words (+ (* slot 5) 3)) 3))
        (:control (setf (aref controls slot) 128))
        (:live-empty (setf (aref controls slot) 255))
        (:empty-live (setf (aref controls (1+ slot)) 7)))
      (multiple-value-bind (highs lows) (hash-map-arrays 16)
        (hash-map-fault f source highs lows
                        (ecase scenario
                          (:payload :index-slot-inconsistent) (:sequence :index-slot-sequence-corrupt)
                          (:odd :primary-rebuild-writer-state) (:control :primary-control-corrupt)
                          (:live-empty :primary-rebuild-live-control) (:empty-live :primary-rebuild-empty-control))))
      (when (member scenario '(:payload :sequence))
        (is (eq :faulted (s::banco-slot-health (p::frammento-indice-bank source))))))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-hash-map-corrupt-arena-and-live-count
  (dolist (scenario '(:used :range :count))
    (let* ((f (hash-map-fixture 0 0 :capacity 16 :arena-bytes 8))
           (source (primary-current f)))
      (hash-map-put f (primary-key 11 12) 1)
      (hash-map-put f (primary-key 13 14 15) 2)
      (ecase scenario
        (:used (setf (p::frammento-indice-used source) 9))
        (:range (setf (p::frammento-indice-used source) 2))
        (:count (setf (p::frammento-indice-live source) 3)))
      (multiple-value-bind (highs lows) (hash-map-arrays 16)
        (hash-map-fault f source highs lows
                        (ecase scenario (:used :primary-rebuild-arena-used)
                          (:range :primary-rebuild-key-range) (:count :primary-rebuild-live-count))
                        (eq scenario :used))))))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(deftest test-REQ-IDX-005-hash-map-missing-root-faults
  (let* ((f (hash-map-fixture 0 0)) (source (primary-current f))
         (index (primary-fixture-index f)))
    (setf (p::indice-primario-root index) nil)
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-fault f source highs lows :primary-index-missing-root t))))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-005-hash-map-internal-digest-faults
  (let* ((f (hash-map-fixture 0 0)) (entry (hash-map-put f (primary-key 42 43) 1))
         (source (primary-current f))
         (slot (first (first (hash-map-physical-slots source (list entry)))))
         (controls (p::frammento-indice-controls source)))
    ;; Byte ancora valido, payload ancora vivo: e la verifica del digest interno a rilevarlo.
    (setf (aref controls slot) (logxor 1 (aref controls slot)))
    (multiple-value-bind (highs lows) (hash-map-arrays 32)
      (hash-map-fault f source highs lows :primary-hash-source-digest))))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-IDX-001-hash-kernel-fault-propagates-owner
  (dolist (mode '(:key :map))
    (let* ((f (hash-map-fixture 0 0)) (key (primary-key 27 28))
           (entry (hash-map-put f key 1)) (source (primary-current f))
           (index (primary-fixture-index f))
           (failure (make-condition 'invariant-violation :reason :hash-tail-progress)))
      (declare (ignore entry))
      (multiple-value-bind (highs lows) (hash-map-arrays 32)
        (let ((h (copy-seq highs)) (l (copy-seq lows)))
          (hash-map-with-fi
           'arcdocdb.hash64:xxh64
           (lambda (original) (declare (ignore original))
             (lambda (&rest arguments) (declare (ignore arguments)) (error failure)))
           (lambda ()
             (is (handler-case
                     (progn (ecase mode
                              (:key (p:digest-chiave-indice index key 0 (length key)))
                              (:map (p:calcola-digests-frammento index source highs lows 0 0))) nil)
                   (invariant-violation (condition) (eq condition failure))))))
          (is (eq :faulted (p::indice-primario-health index)))
          (is (equalp h highs)) (is (equalp l lows)))))))
