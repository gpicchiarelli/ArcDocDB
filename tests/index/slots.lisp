;;;; Test sequenziali v2: configurazione, payload, seqlock e identita di rilocazione.
;;;; OWNER: ogni test possiede banco e buffer; FI solo senza worker attivi.
;;;; SHARED: nessuno stato di prodotto condiviso tra test.
(in-package #:arcdocdb.index.slots.tests)
(declaim (optimize (safety 3) (debug 3)))

;;; REQ: REQ-AFF-003
(deftest test-REQ-AFF-003-slot-deftest-expansion-registers-without-running
  (let ((expanded (macroexpand-1 '(deftest test-REQ-IDX-003-slot-expansion-fixture :ok))))
    (is (equal '(progn
                 (declaim (ftype (function () t) test-REQ-IDX-003-slot-expansion-fixture))
                 (defun test-REQ-IDX-003-slot-expansion-fixture ()
                   "Fixture bounded; segnala il fallimento delle asserzioni." :ok)
                 (pushnew 'test-REQ-IDX-003-slot-expansion-fixture *tests*))
               expanded))
    (is (not (member 'test-REQ-IDX-003-slot-expansion-fixture *tests*)))))

;;; REQ: REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-slot-v2-format-limits-match-adr-0048
  (is (= 24 +header-bytes+))
  (is (= 16777216 +max-document-bytes+))
  (is (= 16842775 +max-record-bytes+))
  (is (= 8 arcdocdb.index.slots::+slot-attempts+))
  (is (= (ash 1 62) arcdocdb.index.slots::+slot-sequence-limit+)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-slot-default-bank-zeroed-fixed-u64-layout
  (let ((bank (crea-banco-slot)))
    (is (= 8192 (arcdocdb.index.slots::banco-slot-capacity bank)))
    (is (null (arcdocdb.index.slots::banco-slot-retained bank)))
    (is (eq :writable (arcdocdb.index.slots::banco-slot-state bank)))
    (is (eq :open (arcdocdb.index.slots::banco-slot-health bank)))
    (is (typep (arcdocdb.index.slots::banco-slot-words bank)
               '(simple-array (unsigned-byte 64) (40960))))
    (is (every #'zerop (arcdocdb.index.slots::banco-slot-words bank)))
    (slot-read-empty bank 0) (slot-read-empty bank 8191)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-maximum-capacity-and-last-index
  (dolist (retained '(nil t))
    (let* ((stride (if retained 6 5)) (budget (* 65536 stride 8))
           (bank (crea-banco-slot :capacity 65536 :retained-p retained :budget-bytes budget))
           (source (slot-payload :end (if retained #x8000000000000030 0))))
      (is (= (* 65536 stride) (length (arcdocdb.index.slots::banco-slot-words bank))))
      (is (= (* 65535 stride) (arcdocdb.index.slots::base-slot bank 65535)))
      (is (null (pubblica-slot-v2 bank 65535 source)))
      (slot-read-equals bank 65535 source)
      (slot-read-empty bank 65534))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-slot-negative-capacity-configuration
  (slot-error (lambda () (crea-banco-slot :capacity -1))
              'invalid-argument :index-slot-configuration))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-slot-zero-capacity-configuration
  (slot-error (lambda () (crea-banco-slot :capacity 0))
              'invalid-argument :index-slot-configuration))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-slot-over-capacity-configuration
  (slot-error (lambda () (crea-banco-slot :capacity 65537))
              'invalid-argument :index-slot-configuration))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-slot-negative-budget-configuration
  (slot-error (lambda () (crea-banco-slot :capacity 1 :budget-bytes -1))
              'invalid-argument :index-slot-configuration))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-slot-zero-budget-configuration
  (slot-error (lambda () (crea-banco-slot :capacity 1 :budget-bytes 0))
              'invalid-argument :index-slot-configuration))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-payload-budget-exact-and-one-byte-short
  (dolist (retained '(nil t))
    (let* ((bytes (if retained 48 40))
           (bank (crea-banco-slot :capacity 1 :retained-p retained :budget-bytes bytes)))
      (slot-read-empty bank 0)
      (slot-error (lambda () (crea-banco-slot :capacity 1 :retained-p retained
                                            :budget-bytes (1- bytes)))
                  'resource-exhausted :index-slot-memory-budget))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-range-refused-by-every-indexed-api
  (let* ((bank (crea-banco-slot :capacity 2)) (source (slot-payload))
         (replacement (slot-payload :offset 96)) (output (slot-buffer 1 2 3 4 5)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (dolist (index '(-1 2 65536 #xffffffffffffffff))
      (dolist (thunk (list (lambda () (leggi-slot-v2 bank index output))
                           (lambda () (pubblica-slot-v2 bank index source))
                           (lambda () (rimuovi-slot-v2 bank index))
                           (lambda () (credito-scrittura-slot bank index))
                           (lambda () (riloca-slot-v2 bank index source replacement))))
        (slot-refusal bank thunk 'invalid-argument :index-slot-range source replacement output)))
    (slot-read-equals bank 0 source)))

;;; REQ: REQ-IDX-001 REQ-IDX-003
(deftest test-REQ-IDX-001-slot-csn-full-u64-beyond-fixnum
  (let ((bank (crea-banco-slot :capacity 1)))
    (dolist (csn (list 1 (1+ most-positive-fixnum) #x8000000000000000 #xffffffffffffffff))
      (let* ((source (slot-payload :csn csn :segment #xffffffff)) (before (copy-seq source)))
        (is (null (pubblica-slot-v2 bank 0 source)))
        (slot-read-equals bank 0 source)
        (is (equalp before source))))
    (is (= 8 (slot-sequence bank 0)))))

;;; REQ: REQ-IDX-003 REQ-IDX-006
(deftest test-REQ-IDX-003-slot-republish-remove-and-reuse-isolates-neighbors
  (dolist (retained '(nil t))
    (let* ((bank (crea-banco-slot :capacity 3 :retained-p retained))
           (a (slot-payload :end (if retained #x8000000000000030 0)))
           (b (slot-payload :csn #x8000000000000031 :end (if retained #x8000000000000040 0))))
      (is (null (pubblica-slot-v2 bank 0 a)))
      (is (null (pubblica-slot-v2 bank 1 b)))
      (is (null (pubblica-slot-v2 bank 0 b)))
      (slot-read-equals bank 0 b) (slot-read-equals bank 1 b) (slot-read-empty bank 2)
      (is (= 4 (slot-sequence bank 0)))
      (is (null (rimuovi-slot-v2 bank 0)))
      (slot-read-empty bank 0)
      (is (= 6 (slot-sequence bank 0)))
      (let ((before (slot-image bank)))
        (is (null (rimuovi-slot-v2 bank 0)))
        (is (equalp before (slot-image bank))))
      (is (null (pubblica-slot-v2 bank 0 a)))
      (slot-read-equals bank 0 a) (slot-read-equals bank 1 b)
      (is (= 8 (slot-sequence bank 0))))))

;;; REQ: REQ-IDX-003 REQ-IDX-006
(deftest test-REQ-IDX-006-slot-removal-clears-every-retained-word
  (let* ((bank (crea-banco-slot :capacity 1 :retained-p t))
         (source (slot-payload :end #xffffffffffffffff)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (is (null (rimuovi-slot-v2 bank 0)))
    (is (equalp #(0 0 0 4 0 0) (arcdocdb.index.slots::banco-slot-words bank)))
    (slot-read-empty bank 0)))

;;; REQ: REQ-LIM-001 REQ-IDX-001
(deftest test-REQ-LIM-001-slot-key-length-boundaries-1-255-256-65535
  (let ((bank (crea-banco-slot :capacity 1)))
    (dolist (length '(1 255 256 65535))
      (let ((source (slot-payload :key-length length)))
        (is (null (pubblica-slot-v2 bank 0 source)))
        (slot-read-equals bank 0 source)))))

;;; REQ: REQ-LIM-001
(deftest test-REQ-LIM-001-slot-zero-key-length-refused
  (slot-reject-source (slot-payload :key-length 0)))

;;; REQ: REQ-LIM-001 REQ-AFF-004
(deftest test-REQ-LIM-001-slot-key-reserved-bits-refused
  (dolist (bit '(56 63))
    (let ((source (slot-payload)))
      (setf (aref source 2) (logior (aref source 2) (ash 1 bit)))
      (slot-reject-source source))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-IDX-001-slot-key-live-flag-required
  (dolist (flag '(0 2 255))
    (let ((source (slot-payload)))
      (setf (ldb (byte 8 48) (aref source 2)) flag)
      (slot-reject-source source))))

;;; REQ: REQ-LIM-001 REQ-AFF-008
(deftest test-REQ-LIM-001-slot-key-arena-end-at-u32-exclusive-limit
  (let ((bank (crea-banco-slot :capacity 1)))
    (dolist (length '(1 65535))
      (let ((source (slot-payload :key-offset (- #x100000000 length) :key-length length)))
        (is (null (pubblica-slot-v2 bank 0 source)))
        (slot-read-equals bank 0 source)))))

;;; REQ: REQ-LIM-001 REQ-AFF-008
(deftest test-REQ-LIM-001-slot-key-arena-overflow-by-one-refused
  (slot-reject-source (slot-payload :key-offset #xffffffff :key-length 2)))

;;; REQ: REQ-LIM-001 REQ-AFF-004
(deftest test-REQ-LIM-001-slot-record-reserved-bits-refused
  (dolist (bit '(32 63))
    (let ((source (slot-payload)))
      (setf (aref source 3) (logior (aref source 3) (ash 1 bit)))
      (slot-reject-source source))))

;;; REQ: REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-slot-minimum-record-header-plus-key-accepted
  (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload :document-length 0)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (slot-read-equals bank 0 source)))

;;; REQ: REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-slot-record-shorter-than-header-plus-key-refused
  (let ((source (slot-payload :document-length 0)))
    (decf (aref source 3))
    (slot-reject-source source)))

;;; REQ: REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-slot-exact-document-and-record-maxima-accepted
  (let ((bank (crea-banco-slot :capacity 1)))
    (dolist (length '(1 65535))
      (let ((source (slot-payload :key-length length :document-length 16777216)))
        (is (null (pubblica-slot-v2 bank 0 source)))
        (slot-read-equals bank 0 source)
        (when (= length 65535) (is (= 16842775 (aref source 3))))))))

;;; REQ: REQ-LIM-003
(deftest test-REQ-LIM-003-slot-document-overflow-below-record-maximum-refused
  (let ((source (slot-payload :key-length 1 :document-length 16777217)))
    (is (< (aref source 3) +max-record-bytes+))
    (slot-reject-source source)))

;;; REQ: REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-slot-record-maximum-plus-one-refused
  (slot-reject-source (slot-payload :key-length 65535 :document-length 16777217)))

;;; REQ: REQ-LIM-001 REQ-AFF-008
(deftest test-REQ-LIM-001-slot-record-end-exact-segment-limit-accepted
  (let* ((bank (crea-banco-slot :capacity 1))
         (source (slot-payload :offset (- #xffffffff 29) :segment #xffffffff)))
    (is (= 29 (aref source 3)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (slot-read-equals bank 0 source)))

;;; REQ: REQ-LIM-001 REQ-AFF-008
(deftest test-REQ-LIM-001-slot-record-end-overflow-by-one-refused
  (slot-reject-source (slot-payload :offset (- #xffffffff 28))))

;;; REQ: REQ-IDX-003
(deftest test-REQ-IDX-003-slot-zero-csn-live-payload-refused
  (slot-reject-source (slot-payload :csn 0)))

;;; REQ: REQ-IDX-001 REQ-IDX-003
(deftest test-REQ-IDX-003-slot-primary-end-must-be-zero
  (slot-reject-source (slot-payload :end #x8000000000000030)))

;;; REQ: REQ-IDX-003 REQ-IDX-005
(deftest test-REQ-IDX-003-slot-retained-exclusive-interval-full-u64
  (let ((bank (crea-banco-slot :capacity 1 :retained-p t)))
    (dolist (bounds '((1 2) (#x8000000000000029 #x8000000000000030)
                      (#xfffffffffffffffe #xffffffffffffffff)))
      (let ((source (slot-payload :csn (first bounds) :end (second bounds))))
        (is (null (pubblica-slot-v2 bank 0 source)))
        (slot-read-equals bank 0 source)))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-IDX-003-slot-retained-zero-equal-and-earlier-end-refused
  (dolist (end '(0 #x8000000000000029 #x8000000000000028))
    (slot-reject-source (slot-payload :end end) :retained-p t)))

;;; REQ: REQ-IDX-003 REQ-AFF-008
(deftest test-REQ-IDX-003-slot-retained-u64-max-start-has-no-valid-end
  (slot-reject-source (slot-payload :csn #xffffffffffffffff :end #xffffffffffffffff)
                      :retained-p t))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-IDX-003-slot-empty-predicate-checks-all-five-fields
  (is (arcdocdb.index.slots::contenuto-vuoto-p 0 0 0 0 0))
  (dotimes (field 5)
    (let ((words (list 0 0 0 0 0)))
      (setf (nth field words) 1)
      (is (not (apply #'arcdocdb.index.slots::contenuto-vuoto-p words))))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-IDX-003-slot-internal-validation-empty-live-and-malformed
  (let ((bank (crea-banco-slot :capacity 1)) (source (slot-payload)))
    (is (null (arcdocdb.index.slots::verifica-campi-slot bank 0 0 0 0 0)))
    (is (arcdocdb.index.slots::contenuto-vivo-valido-p
         (aref source 0) (aref source 1) (aref source 2) (aref source 3) 0 nil))
    (is (arcdocdb.index.slots::metadati-chiave-validi-p (aref source 2)))
    (is (arcdocdb.index.slots::record-slot-valido-p
         (aref source 1) (aref source 2) (aref source 3)))
    (slot-fault bank (lambda () (arcdocdb.index.slots::verifica-campi-slot bank 0 1 0 0 0))
                :index-slot-inconsistent)))

;;; REQ: REQ-IDX-003 REQ-IDX-005
(deftest test-REQ-IDX-005-slot-freeze-idempotent-readable-and-all-writers-refused
  (dolist (retained '(nil t))
    (let* ((bank (crea-banco-slot :capacity 2 :retained-p retained))
           (source (slot-payload :end (if retained #x8000000000000030 0)))
           (replacement (copy-seq source)))
      (incf (aref replacement 1) 16)
      (is (null (pubblica-slot-v2 bank 0 source)))
      (is (null (congela-banco-slot bank)))
      (let ((before (slot-image bank)))
        (is (null (congela-banco-slot bank)))
        (is (equalp before (slot-image bank))))
      (is (eq :frozen (arcdocdb.index.slots::banco-slot-state bank)))
      (slot-read-equals bank 0 source) (slot-read-empty bank 1)
      (dolist (thunk (list (lambda () (pubblica-slot-v2 bank 0 source))
                           (lambda () (rimuovi-slot-v2 bank 0))
                           (lambda () (credito-scrittura-slot bank 0))
                           (lambda () (riloca-slot-v2 bank 0 source replacement))))
        (slot-refusal bank thunk 'invalid-argument :index-slot-frozen source replacement)))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-AFF-004-slot-invalidation-idempotent-terminal-and-preserves-data
  (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload))
         (replacement (slot-payload :offset 96)) (output (slot-buffer 1 2 3 4 5)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (let ((words (copy-seq (arcdocdb.index.slots::banco-slot-words bank))))
      (is (null (invalida-banco-slot bank)))
      (is (null (invalida-banco-slot bank)))
      (is (eq :faulted (arcdocdb.index.slots::banco-slot-health bank)))
      (is (equalp words (arcdocdb.index.slots::banco-slot-words bank))))
    (dolist (thunk (list (lambda () (leggi-slot-v2 bank 0 output))
                         (lambda () (pubblica-slot-v2 bank 0 source))
                         (lambda () (rimuovi-slot-v2 bank 0))
                         (lambda () (credito-scrittura-slot bank 0))
                         (lambda () (riloca-slot-v2 bank 0 source replacement))
                         (lambda () (congela-banco-slot bank))))
      (slot-refusal bank thunk 'invariant-violation :index-slot-faulted source replacement output))))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-AFF-004
(deftest test-REQ-AFF-004-slot-fault-after-freeze-keeps-both-terminal-states
  (let ((bank (crea-banco-slot :capacity 1)) (output (slot-buffer 1 2 3 4 5)))
    (is (null (congela-banco-slot bank)))
    (is (null (invalida-banco-slot bank)))
    (is (eq :frozen (arcdocdb.index.slots::banco-slot-state bank)))
    (slot-refusal bank (lambda () (leggi-slot-v2 bank 0 output))
                  'invariant-violation :index-slot-faulted output)
    (slot-refusal bank (lambda () (congela-banco-slot bank))
                  'invariant-violation :index-slot-faulted)))

;;; REQ: REQ-IDX-003 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-slot-odd-retry-limit-preserves-output-and-skips-transient-validation
  (dolist (retained '(nil t))
    (let* ((bank (crea-banco-slot :capacity 1 :retained-p retained))
           (output (slot-buffer 101 102 103 104 105)) (before (copy-seq output)))
      ;; Dati volutamente incoerenti: non sono un campione stabile interpretabile.
      (slot-fi-word bank 0 arcdocdb.index.slots::+slot-key+ #xffffffffffffffff)
      (slot-fi-word bank 0 arcdocdb.index.slots::+slot-sequence+ 1)
      (is (eq :retry (arcdocdb.index.slots::tenta-lettura-slot bank 0 output)))
      (is (equal '(:retry-limit) (multiple-value-list (leggi-slot-v2 bank 0 output))))
      (is (equalp before output))
      (is (eq :open (arcdocdb.index.slots::banco-slot-health bank)))
      (is (= 1 (slot-sequence bank 0))))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-AFF-004-slot-reader-corrupt-sequence-threshold-and-u64-max
  (dolist (sequence (list (ash 1 62) #xffffffffffffffff))
    (let ((bank (crea-banco-slot :capacity 1)) (output (slot-buffer 1 2 3 4 5)))
      (slot-fi-word bank 0 arcdocdb.index.slots::+slot-sequence+ sequence)
      (slot-fault bank (lambda () (leggi-slot-v2 bank 0 output))
                  :index-slot-sequence-corrupt output))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-AFF-004-slot-writer-odd-and-threshold-sequences-fault
  (dolist (sequence (list 1 (ash 1 62) #xffffffffffffffff))
    (dolist (operation '(:credit :publish :remove :relocate))
      (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload))
             (replacement (slot-payload :offset 96)))
        (slot-fi-word bank 0 arcdocdb.index.slots::+slot-sequence+ sequence)
        (slot-fault bank
                    (lambda ()
                      (case operation
                        (:credit (credito-scrittura-slot bank 0))
                        (:publish (pubblica-slot-v2 bank 0 source))
                        (:remove (rimuovi-slot-v2 bank 0))
                        (:relocate (riloca-slot-v2 bank 0 source replacement))
                        (otherwise (error 'invariant-violation :reason :slot-test-operation))))
                    :index-slot-writer-sequence source replacement)))))

;;; REQ: REQ-IDX-003 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-initial-credit-and-one-per-mutation
  (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload))
         (initial (/ (- (ash 1 62) 2) 2)))
    (is (= initial (credito-scrittura-slot bank 0)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (is (= (1- initial) (credito-scrittura-slot bank 0)))
    (is (null (rimuovi-slot-v2 bank 0)))
    (is (= (- initial 2) (credito-scrittura-slot bank 0)))
    (is (null (rimuovi-slot-v2 bank 0)))
    (is (= (- initial 2) (credito-scrittura-slot bank 0)))))

;;; REQ: REQ-IDX-003 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-last-credit-consumed-without-wrap
  (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload)))
    (slot-fi-word bank 0 arcdocdb.index.slots::+slot-sequence+ (- (ash 1 62) 4))
    (is (= 1 (credito-scrittura-slot bank 0)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (is (= (- (ash 1 62) 2) (slot-sequence bank 0)))
    (is (zerop (credito-scrittura-slot bank 0)))
    (slot-read-equals bank 0 source)
    (slot-refusal bank (lambda () (pubblica-slot-v2 bank 0 source))
                  'resource-exhausted :index-slot-seqlock-rebuild source)))

;;; REQ: REQ-IDX-003 REQ-IDX-004 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-exhausted-live-publish-remove-and-relocate-refused
  (dolist (retained '(nil t))
    (let* ((bank (crea-banco-slot :capacity 1 :retained-p retained))
           (source (slot-payload :end (if retained #x8000000000000030 0)))
           (replacement (copy-seq source)))
      (incf (aref replacement 1) 16)
      (is (null (pubblica-slot-v2 bank 0 source)))
      (slot-fi-word bank 0 arcdocdb.index.slots::+slot-sequence+ (- (ash 1 62) 2))
      (is (zerop (credito-scrittura-slot bank 0)))
      (dolist (thunk (list (lambda () (pubblica-slot-v2 bank 0 replacement))
                           (lambda () (rimuovi-slot-v2 bank 0))
                           (lambda () (riloca-slot-v2 bank 0 source replacement))))
        (slot-refusal bank thunk 'resource-exhausted :index-slot-seqlock-rebuild source replacement))
      (slot-read-equals bank 0 source))))

;;; REQ: REQ-IDX-006 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-exhausted-empty-removal-is-idempotent
  (let ((bank (crea-banco-slot :capacity 1)))
    (slot-fi-word bank 0 arcdocdb.index.slots::+slot-sequence+ (- (ash 1 62) 2))
    (let ((before (slot-image bank)))
      (is (null (rimuovi-slot-v2 bank 0)))
      (is (equalp before (slot-image bank)))
      (is (zerop (credito-scrittura-slot bank 0)))
      (slot-read-empty bank 0))))

;;; REQ: REQ-IDX-004 REQ-AFF-008
(deftest test-REQ-AFF-008-slot-exhausted-relocation-noops-need-no-credit
  (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload))
         (stale (slot-payload :offset 48)) (replacement (slot-payload :offset 96)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (slot-fi-word bank 0 arcdocdb.index.slots::+slot-sequence+ (- (ash 1 62) 2))
    (let ((before (slot-image bank)))
      (is (riloca-slot-v2 bank 0 source (copy-seq source)))
      (is (null (riloca-slot-v2 bank 0 stale replacement)))
      (is (equalp before (slot-image bank)))
      (is (zerop (credito-scrittura-slot bank 0)))
      (slot-read-equals bank 0 source))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-AFF-004-slot-stable-corrupt-fields-fault-reader-before-copy
  (dolist (retained '(nil t))
    (dolist (fault (append (list (cons arcdocdb.index.slots::+slot-csn+ 0)
                                 (cons arcdocdb.index.slots::+slot-key+ #x100000000000020)
                                 (cons arcdocdb.index.slots::+slot-length+ #x10000001d)
                                 (cons arcdocdb.index.slots::+slot-location+ #xffffffffffffffff))
                           (when retained (list (cons arcdocdb.index.slots::+slot-end+ 0)))))
      (let* ((bank (crea-banco-slot :capacity 1 :retained-p retained))
             (source (slot-payload :end (if retained #x8000000000000030 0)))
             (output (slot-buffer 1 2 3 4 5)))
        (is (null (pubblica-slot-v2 bank 0 source)))
        (slot-fi-word bank 0 (car fault) (cdr fault))
        (slot-fault bank (lambda () (leggi-slot-v2 bank 0 output))
                    :index-slot-inconsistent output)))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(deftest test-REQ-AFF-004-slot-partial-empty-faults-reader-and-writer
  (dolist (field '(1 2 4))
    (dolist (reader '(nil t))
      (let ((bank (crea-banco-slot :capacity 1)) (output (slot-buffer 1 2 3 4 5)))
        (slot-fi-word bank 0 field 1)
        (slot-fault bank (lambda () (if reader (leggi-slot-v2 bank 0 output)
                                       (credito-scrittura-slot bank 0)))
                    :index-slot-inconsistent output)))))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-primary-and-retained-changes-only-location
  (dolist (retained '(nil t))
    (let* ((bank (crea-banco-slot :capacity 1 :retained-p retained))
           (source (slot-payload :end (if retained #xffffffffffffffff 0)))
           (replacement (copy-seq source)))
      (setf (aref replacement 1) #xffffffff00000080)
      (is (null (pubblica-slot-v2 bank 0 source)))
      (is (riloca-slot-v2 bank 0 source replacement))
      (slot-read-equals bank 0 replacement)
      (is (= 4 (slot-sequence bank 0)))
      (let ((before (slot-image bank)))
        (is (null (riloca-slot-v2 bank 0 source replacement)))
        (is (equalp before (slot-image bank))))
      (is (equalp (slot-payload :end (if retained #xffffffffffffffff 0)) source)))))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-stale-csn-does-not-overwrite
  (slot-stale-relocation 0 #x8000000000000028))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-stale-location-does-not-overwrite
  (slot-stale-relocation 1 #x1f00000030))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-stale-key-metadata-does-not-overwrite
  (slot-stale-relocation 2 #x1000200000021))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-stale-record-length-does-not-overwrite
  (slot-stale-relocation 3 30))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-stale-retained-end-does-not-overwrite
  (slot-stale-relocation 4 #x8000000000000031 :retained-p t))

;;; REQ: REQ-IDX-004 REQ-AFF-004
(deftest test-REQ-IDX-004-slot-relocation-csn-change-refused
  (slot-reject-relocation-change 0 #x8000000000000028))

;;; REQ: REQ-IDX-004 REQ-AFF-004
(deftest test-REQ-IDX-004-slot-relocation-key-change-refused
  (slot-reject-relocation-change 2 #x1000200000021))

;;; REQ: REQ-IDX-004 REQ-AFF-004
(deftest test-REQ-IDX-004-slot-relocation-record-length-change-refused
  (slot-reject-relocation-change 3 30))

;;; REQ: REQ-IDX-004 REQ-AFF-004
(deftest test-REQ-IDX-004-slot-relocation-retained-end-change-refused
  (slot-reject-relocation-change 4 #x8000000000000031 :retained-p t))

;;; REQ: REQ-IDX-004 REQ-AFF-004
(deftest test-REQ-IDX-004-slot-relocation-invalid-expected-and-replacement-refused
  (dolist (bad-expected '(nil t))
    (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload))
           (expected (copy-seq source)) (replacement (slot-payload :offset 96)))
      (setf (aref (if bad-expected expected replacement) 3) #x10000001d)
      (is (null (pubblica-slot-v2 bank 0 source)))
      (slot-refusal bank (lambda () (riloca-slot-v2 bank 0 expected replacement))
                    'invalid-argument :index-slot-payload expected replacement)
      (slot-read-equals bank 0 source))))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-empty-is-a-noop
  (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload))
         (replacement (slot-payload :offset 96)) (before (slot-image bank)))
    (is (null (riloca-slot-v2 bank 0 source replacement)))
    (is (equalp before (slot-image bank)))
    (slot-read-empty bank 0)))

;;; REQ: REQ-IDX-004
(deftest test-REQ-IDX-004-slot-relocation-equal-location-never-consumes-credit
  (let* ((bank (crea-banco-slot :capacity 1)) (source (slot-payload)))
    (is (null (pubblica-slot-v2 bank 0 source)))
    (let ((before (slot-image bank)) (credit (credito-scrittura-slot bank 0)))
      (is (riloca-slot-v2 bank 0 source (copy-seq source)))
      (is (equalp before (slot-image bank)))
      (is (= credit (credito-scrittura-slot bank 0)))
      (slot-read-equals bank 0 source))))
