;;;; Oracoli indipendenti per gli ordinamenti DECISION e lettori concorrenti.
(in-package #:arcdocdb.recovery.tests)

(defun radix-test-packed-ids (ids)
  "Concatena gli ID16 dichiarati dalla fixture, senza primitive del prodotto."
  (let ((packed (make-array (* 16 (length ids)) :element-type '(unsigned-byte 8))))
    (loop for id in ids for position from 0
          do (replace packed id :start1 (* 16 position)))
    packed))

(defun radix-test-id-number (packed start)
  "Interpreta un ID16 come intero big-endian, indipendentemente dal comparatore."
  (reduce (lambda (number byte) (+ (* number 256) byte)) packed
          :start start :end (+ start 16) :initial-value 0))

(defun radix-test-id-oracle (packed)
  "Ordina interi con CL:STABLE-SORT e ricostruisce tutti i 128 bit degli ID."
  (let* ((count (/ (length packed) 16))
         (numbers (make-array count :element-type t))
         (result (make-array (length packed) :element-type '(unsigned-byte 8))))
    (dotimes (i count) (setf (aref numbers i) (radix-test-id-number packed (* i 16))))
    (setf numbers (stable-sort numbers #'<))
    (dotimes (i count)
      (dotimes (byte 16)
        (setf (aref result (+ (* i 16) byte))
              (ldb (byte 8 (* 8 (- 15 byte))) (aref numbers i)))))
    result))

(defun radix-test-id-fixture (count pattern)
  "ID unici, cardinalità nota e seme locale; ultimi due byte dichiarano l'identità."
  (let ((packed (make-array (* count 16) :element-type '(unsigned-byte 8)))
        (state 193))
    (dotimes (position count)
      (let ((number (- count position 1)) (start (* position 16)))
        (dotimes (byte 14)
          (setf state (logand #xffffffff (+ (* state 1664525) 1013904223)))
          (setf (aref packed (+ start byte))
                (case pattern
                  (:uniform #xa5)
                  (:random (ldb (byte 8 24) state))
                  (:cluster #x80)
                  (otherwise (error "Pattern della fixture sconosciuto: ~S" pattern)))))
        (when (eq pattern :cluster)
          (setf (aref packed start) (mod (floor number 17) 3)
                (aref packed (+ start 7)) (if (oddp number) #xff 0)))
        (setf (aref packed (+ start 14)) (ldb (byte 8 8) number)
              (aref packed (+ start 15)) (ldb (byte 8 0) number))))
    packed))

(defun radix-test-assert-id-sorts (packed source-offset)
  "Confronta radix e merge con un oracolo numerico, su copie private distinte."
  (let ((expected (radix-test-id-oracle packed)) (before (copy-seq packed))
        (count (/ (length packed) 16)))
    (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                          #'arcdocdb.recovery.decisions::sort-participants))
      (let ((result (funcall sorter (copy-seq packed) count source-offset)))
        (is (typep result '(simple-array (unsigned-byte 8) (*))))
        (is (equalp expected result))))
    (is (equalp packed before))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-participant-cardinalities-and-patterns
  (dolist (count '(0 1 2 3 5 17 256 257 65535))
    (dolist (pattern '(:uniform :random :cluster))
      (radix-test-assert-id-sorts (radix-test-id-fixture count pattern)
                                #xffffffffffffffff))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-FOR-003
(deftest test-REQ-TXM-001-radix-participant-every-byte-and-bit
  (let ((base (make-array 16 :element-type '(unsigned-byte 8) :initial-element #x80)))
    (dotimes (byte 16)
      (dotimes (bit 8)
        (let ((changed (copy-seq base)))
          (setf (aref changed byte) (logxor #x80 (ash 1 bit)))
          (radix-test-assert-id-sorts (radix-test-packed-ids (list base changed)) 17)
          (radix-test-assert-id-sorts (radix-test-packed-ids (list changed base)) 17))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-017
(deftest test-REQ-TXM-005-radix-duplicate-participant-offset
  (dolist (offset '(0 4294967296 18446744073709551615))
    (dolist (count '(2 3 5 17 257))
      (let ((packed (radix-test-id-fixture count :random)))
        (replace packed packed :start1 (* 16 (1- count)) :end1 (* 16 count)
                                :start2 0 :end2 16)
        (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                              #'arcdocdb.recovery.decisions::sort-participants))
          (let ((condition (signals corruption-detected
                                   (funcall sorter (copy-seq packed) count offset)
                                   :decision-duplicate-participant)))
            (is (= offset (error-offset condition)))))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-participant-shape-before-sort
  (dolist (size '(0 15 17 32))
    (let ((packed (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
      (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                            #'arcdocdb.recovery.decisions::sort-participants))
        (signals arcdocdb.conditions:invariant-violation
                 (funcall sorter packed 1 0) :decision-participant-size)))))

(defun radix-test-entry-fixture (count pattern)
  "Entry dichiarate con offset crescenti; TXID uguali conservano l'ordine fisico."
  (let ((entries (make-array count :element-type t)) (state 913)
        (participants (radix-test-packed-ids (list (participant-id 0) (participant-id 1))))
        (extremes (vector 0 #xffffffffffffffff #x8000000000000000
                          #x7fffffffffffffff #x100000000 #xff #x100 1)))
    (dotimes (i count)
      (setf state (logand #xffffffffffffffff
                         (+ (* state 6364136223846793005) 1442695040888963407)))
      (let ((txid (case pattern
                    (:uniform #xffffffffffffffff)
                    (:random state)
                    (:cluster (aref extremes (mod i (length extremes))))
                    (:dominant (if (= i (1- count)) 0 #xffffffffffffffff))
                    (otherwise (error "Pattern delle entry sconosciuto: ~S" pattern)))))
        (setf (aref entries i)
              (arcdocdb.recovery.decisions::%make-decision-entry
                txid (- #xffffffffffffffff i) 2 participants (+ (ash 1 63) (* i 64))))))
    entries))

(defun radix-test-entry-oracle (entries)
  "CL:STABLE-SORT sul solo TXID; l'identità delle entry prova anche la stabilità."
  (stable-sort (copy-seq entries) #'< :key #'arcdocdb.recovery.decisions::%entry-txid))

(defun radix-test-assert-entry-sorts (entries)
  "Oracolo indipendente dal merge e dal radix; nessuna ricostruzione dei loro passaggi."
  (let ((expected (radix-test-entry-oracle entries)) (before (copy-seq entries)))
    (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-entries
                          #'arcdocdb.recovery.decisions::sort-entries))
      (let ((result (funcall sorter (copy-seq entries))))
        (is (= (length expected) (length result)))
        (dotimes (i (length expected))
          (is (eq (aref expected i) (aref result i)))
          (when (and (plusp i)
                     (= (arcdocdb.recovery.decisions::%entry-txid (aref result (1- i)))
                        (arcdocdb.recovery.decisions::%entry-txid (aref result i))))
            (is (< (arcdocdb.recovery.decisions::%entry-source-offset (aref result (1- i)))
                   (arcdocdb.recovery.decisions::%entry-source-offset (aref result i))))))))
    (is (equalp entries before))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-entry-cardinalities-patterns-and-stability
  (dolist (count '(0 1 2 3 5 17 256 257 65535))
    (dolist (pattern '(:uniform :random :cluster))
      (radix-test-assert-entry-sorts (radix-test-entry-fixture count pattern)))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-AFF-008-radix-entry-65536-bucket-counts
  ;; Il numero di DECISION fisiche non è limitato al count u16 dei partecipanti.
  ;; Una classe con 65.536 entry e una classe dominante con un outlier
  ;; rendono osservabili sia il conteggio sia il cursore finale oltre u16.
  (dolist (pattern '(:uniform :dominant))
    (radix-test-assert-entry-sorts (radix-test-entry-fixture 65536 pattern))))

;;; REQ: REQ-TXM-001 REQ-TXM-005
(deftest test-REQ-TXM-001-radix-entry-every-txid-bit
  (dotimes (bit 64)
    (let* ((a (arcdocdb.recovery.decisions::%make-decision-entry
                #x8000000000000000 0 2
                (radix-test-id-oracle (radix-test-id-fixture 2 :uniform)) 31))
           (b (arcdocdb.recovery.decisions::%make-decision-entry
                (logxor #x8000000000000000 (ash 1 bit)) 0 2
                (radix-test-id-oracle (radix-test-id-fixture 2 :uniform)) 32)))
      (radix-test-assert-entry-sorts (vector a b))
      (radix-test-assert-entry-sorts (vector b a)))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-entry-shape-before-sort
  (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-entries
                        #'arcdocdb.recovery.decisions::sort-entries))
    (signals arcdocdb.conditions:invariant-violation
             (funcall sorter (vector (arcdocdb.recovery.decisions::%make-decision-entry
                                     0 0 1 (radix-test-id-fixture 1 :uniform) 0)))
             :decision-entry-count)
    (signals arcdocdb.conditions:invariant-violation
             (funcall sorter (vector (arcdocdb.recovery.decisions::%make-decision-entry
                                     0 0 2 (radix-test-id-fixture 1 :uniform) 0)))
             :decision-entry-size)))

(defun radix-test-query-probes (specs)
  "Ogni probe dichiara TXID, ID16 e risposta, senza consultare la tabella del prodotto."
  (append
   (loop for (txid csn ids) in (decision-oracle specs) append
     (list (list txid (first ids) t csn (length ids) t)
           (list txid (participant-id 0 #x7f) t csn (length ids) nil)))
   (list (list 1 (participant-id 0) nil 0 0 nil)
         (list 49 (participant-id 0) nil 0 0 nil)
         (list 51 (participant-id 0) nil 0 0 nil))))

(defun radix-test-query-expected (probes rounds)
  "Output piatto dichiarativo; ciascun worker possiede un vettore della stessa misura."
  (let ((out (make-array (* rounds (length probes) 5)
                         :element-type '(unsigned-byte 64))) (position 0))
    (dotimes (round rounds)
      (dolist (probe probes)
        (destructuring-bind (txid id found csn count member) probe
          (declare (ignore id))
          (dolist (value (list txid (if found 1 0) csn count (if member 1 0)))
            (setf (aref out position) value) (incf position)))))
    out))

(defun radix-test-query-worker (table probes rounds out ready release)
  "Query scalari su tabella condivisa; buffer ID e output sono esclusivi del worker."
  (handler-case
      (let ((id-buffer (make-array 22 :element-type '(unsigned-byte 8) :initial-element #xcc))
            (position 0))
        (sb-thread:signal-semaphore ready)
        (unless (sb-thread:wait-on-semaphore release :timeout 10)
          (error "Worker delle query non rilasciato dalla fixture."))
        (dotimes (round rounds)
          (dolist (probe probes)
            (let ((txid (first probe)) (id (second probe)))
              (replace id-buffer id :start1 3)
              (multiple-value-bind (found csn count)
                  (arcdocdb.recovery.decisions:trova-decisione table txid)
                (setf (aref out position) txid
                      (aref out (+ position 1)) (if found 1 0)
                      (aref out (+ position 2)) csn
                      (aref out (+ position 3)) count
                      (aref out (+ position 4))
                      (if (arcdocdb.recovery.decisions:partecipante-decisione-p
                            table txid id-buffer 3 19) 1 0)))
              (incf position 5))))
        t)
    (error (condition) condition)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-TXM-005-concurrent-immutable-table-queries
  (let* ((specs (append (loop for i below 17 collect
                         (decision-spec (+ 50 (* 2 i)) (if (oddp i) 0 #xffffffffffffffff)
                           (loop for j below (nth (mod i 3) '(3 5 17)) collect
                             (participant-id (+ (* i 32) j) (if (oddp j) #x80 0)))))
                        (list (decision-spec 0 0 (list (participant-id 1) (participant-id 2)))
                              (decision-spec #xffffffffffffffff 17
                                             (list (participant-id 3 #xff)
                                                   (participant-id 4 #xff))))))
         (probes (radix-test-query-probes specs)) (rounds 64) (workers 6)
         (expected (radix-test-query-expected probes rounds))
         (outputs (make-array workers :element-type t))
         (ready (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
         (threads nil) (joined nil))
    (multiple-value-bind (buffer start end)
        (decision-log-fixture (list (permute-decisions specs 193)))
      (let ((table (decision-fixture-read buffer start end)))
        (assert-decision-table table specs '(1 49 51))
        ;; I lettori devono dipendere soltanto dalle copie possedute dalla tabella.
        (fill buffer #xdd)
        (let ((before (copy-seq buffer)))
          (dotimes (i workers)
            (setf (aref outputs i)
                  (make-array (length expected) :element-type '(unsigned-byte 64)
                                                :initial-element #xffffffffffffffff)))
          (unwind-protect
               (progn
                 (dotimes (i workers)
                   (let ((out (aref outputs i)))
                     (push (sb-thread:make-thread
                            (lambda () (radix-test-query-worker table probes rounds out ready release)))
                           threads)))
                 (dotimes (i workers) (is (sb-thread:wait-on-semaphore ready :timeout 10))))
            (sb-thread:signal-semaphore release workers)
            (setf joined (mapcar (lambda (thread)
                                  (sb-thread:join-thread thread :timeout 10 :default :join-failed))
                                threads)))
          (is (= workers (length threads)))
          (is (every (lambda (result) (eq result t)) joined))
          (is (every (lambda (thread) (not (sb-thread:thread-alive-p thread))) threads))
          (dotimes (i workers)
            (is (equalp expected (aref outputs i)))
            (dotimes (j i) (is (not (eq (aref outputs i) (aref outputs j))))))
          (assert-decision-table table specs '(1 49 51))
          (is (equalp buffer before)))))))

(defun radix-test-histogram (&optional (value 0))
  "Stato privato iniettato dalla fixture: 256 conteggi/cursori u64 dichiarati."
  (make-array 256 :element-type '(unsigned-byte 64) :initial-element value))

(defun radix-test-internal-call (name &rest arguments)
  "Invoca il confine interno con dati corrotti senza piegare i tipi statici del test."
  (apply (fdefinition name) arguments))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-prefix-invalid-total
  ;; Tre elementi in una classe non possono appartenere a un input di due.
  ;; Due elementi dichiarati non consumano invece un input di tre.
  (dolist (case '((3 0 2 :decision-radix-count) (2 1 2 :decision-radix-count)
                 (2 0 3 :decision-radix-consumption)))
    (destructuring-bind (frequency second-frequency count reason) case
      (let ((histogram (radix-test-histogram)))
        (setf (aref histogram 0) frequency (aref histogram 129) second-frequency)
        (let ((before (copy-seq histogram)))
          (signals arcdocdb.conditions:invariant-violation
                   (radix-test-internal-call
                    'arcdocdb.recovery.decisions::radix-prefix-starts histogram count)
                   reason)
          (is (equalp before histogram)))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-entry-invalid-object-before-slot-access
  (dolist (object (list nil 42 (bytes 0)))
    (signals arcdocdb.conditions:invariant-violation
             (arcdocdb.recovery.decisions::radix-sort-entries (vector object))
             :decision-entry-shape)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-invalid-digit-before-access
  (let ((ids (radix-test-id-fixture 2 :uniform))
        (entries (radix-test-entry-fixture 2 :cluster)))
    (dolist (digit (list 16 17 most-positive-fixnum))
      (let ((histogram (radix-test-histogram 7)) (target (copy-seq ids)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-id-starts
                                          ids 2 digit histogram)
                 :decision-radix-digit)
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 digit histogram)
                 :decision-radix-digit)
        (is (equalp ids target))
        (is (every (lambda (value) (= value 7)) histogram))))
    (dolist (digit (list 8 9 most-positive-fixnum))
      (let ((histogram (radix-test-histogram 7)) (target (copy-seq entries)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-entry-starts
                                          entries digit histogram)
                 :decision-radix-digit)
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target digit histogram)
                 :decision-radix-digit)
        (is (equalp entries target))
        (is (every (lambda (value) (= value 7)) histogram))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-scatter-invalid-arrays
  (let* ((ids (radix-test-id-fixture 2 :uniform)) (before (copy-seq ids))
         (entries (radix-test-entry-fixture 2 :cluster)) (entries-before (copy-seq entries)))
    (dolist (target (list ids
                         (make-array 15 :element-type '(unsigned-byte 8) :initial-element 0)
                         (make-array 31 :element-type '(unsigned-byte 8) :initial-element 0)
                         (make-array 33 :element-type '(unsigned-byte 8) :initial-element 0)))
      (let ((histogram (radix-test-histogram 7)) (target-before (copy-seq target)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 0 histogram)
                 :decision-radix-arrays)
        (is (equalp target-before target))
        (is (equalp before ids))
        (is (every (lambda (value) (= value 7)) histogram))))
    (let ((histogram (radix-test-histogram 7)))
      (signals arcdocdb.conditions:invariant-violation
               (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                        ids (copy-seq ids) 1 0 histogram)
               :decision-radix-arrays)
      (signals arcdocdb.conditions:invariant-violation
               (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-id-starts
                                        ids 1 0 histogram)
               :decision-participant-size))
    (dolist (target (list entries (make-array 1) (make-array 3)))
      (let ((histogram (radix-test-histogram 7)) (target-before (copy-seq target)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target 0 histogram)
                 :decision-radix-arrays)
        (is (equalp target-before target))
        (is (equalp entries-before entries))
        (is (every (lambda (value) (= value 7)) histogram))))))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-invalid-final-cursors
  (dolist (case '(:decreasing :past-end :incomplete))
    (let ((histogram (radix-test-histogram (if (eq case :incomplete) 1 2))))
      (case case
        (:decreasing (setf (aref histogram 12) 1))
        (:past-end (setf (aref histogram 37) 3)))
      (let ((before (copy-seq histogram)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-check-cursors
                                          histogram 2)
                 (if (eq case :incomplete) :decision-radix-consumption
                     :decision-radix-position))
        (is (equalp before histogram))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-scatter-invalid-cursors
  ;; Le due chiavi distinte partono erroneamente dalla stessa posizione: nessun
  ;; accesso eccede N, ma il cursore finale denuncia la perdita di un elemento.
  (let ((ids (radix-test-id-fixture 2 :uniform))
        (entries (radix-test-entry-fixture 2 :cluster)))
    (dolist (case '(:past-end :incomplete))
      (let ((histogram (radix-test-histogram (if (eq case :past-end) 2 1)))
            (target (copy-seq ids)) (before (copy-seq ids)))
        (when (eq case :incomplete)
          (setf (aref histogram 0) 0 (aref histogram 1) 0))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 15 histogram)
                 (if (eq case :past-end) :decision-radix-position :decision-radix-consumption))
        (is (equalp before ids))
        (when (eq case :past-end) (is (equalp before target))))
      (let ((histogram (radix-test-histogram (if (eq case :past-end) 2 1)))
            (target (copy-seq entries)) (before (copy-seq entries)))
        (when (eq case :incomplete)
          (setf (aref histogram 0) 0 (aref histogram 255) 0))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target 0 histogram)
                 (if (eq case :past-end) :decision-radix-position :decision-radix-consumption))
        (is (equalp before entries))
        (when (eq case :past-end) (is (equalp before target)))))))

(defun radix-test-unpacked-ids (packed)
  "Copie ID16 dichiarate dalla fixture; nessun decoder o comparatore del prodotto."
  (loop for start from 0 below (length packed) by 16
        collect (subseq packed start (+ start 16))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-public-participant-sort-threshold-boundaries
  (let ((threshold arcdocdb.recovery.decisions::+radix-participant-threshold+))
    (is (<= 2 threshold 65534))
    (dolist (count (list (1- threshold) threshold (1+ threshold)))
      (dolist (pattern '(:uniform :random :cluster))
        (let* ((ids (radix-test-unpacked-ids (radix-test-id-fixture count pattern)))
               (specs (list (decision-spec 0 #xffffffffffffffff ids)
                            (decision-spec 0 #xffffffffffffffff (reverse ids)))))
          (dolist (version '(1 2))
            (multiple-value-bind (buffer start end)
                (decision-log-fixture (list specs) :version version :file-offset 4294967296)
              (let ((before (copy-seq buffer)))
                (multiple-value-bind (table prefix status)
                    (decision-fixture-read buffer start end :version version
                                           :file-offset 4294967296 :max-participants (* 2 count))
                  (is (= end prefix)) (is (eq :complete status))
                  (assert-decision-table table specs '(1 1024 1025))
                  (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p
                            table 0 (participant-id 65535 #x7f) 0 16)))
                  (is (equalp before buffer)))))))))))

(defun radix-test-public-entry-specs (count)
  "TXID unici dichiarati, estremi u64, CSN condivisi e ID con bit alto."
  (loop for i below count collect
    (decision-spec (case i (0 0) (1 #xffffffffffffffff) (otherwise (+ (ash 1 32) (* i 257))))
                   (mod i 5)
                   (loop for j below (nth (mod i 3) '(2 3 5)) collect
                     (participant-id (+ (* i 32) j) (if (oddp j) #x80 0))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-public-entry-sort-threshold-boundaries
  (let ((threshold arcdocdb.recovery.decisions::+radix-entry-threshold+))
    (is (<= 3 threshold 65535))
    (dolist (count (list (1- threshold) threshold (1+ threshold)))
      (let ((specs (radix-test-public-entry-specs count))
            (ids (list (participant-id 0 #x80) (participant-id 1 #x80))))
        ;; La soglia riguarda i record fisici anche quando COLLAPSE produrrà un solo TXID.
        (dolist (physical-order
                 (list (reverse specs) (permute-decisions specs 913)
                       (loop for i below count collect
                         (decision-spec #xffffffffffffffff 0 (if (oddp i) (reverse ids) ids)))))
          (dolist (version '(1 2))
            (multiple-value-bind (buffer start end)
                (decision-log-fixture (list physical-order) :version version
                                                           :file-offset 4294967296)
              (let ((before (copy-seq buffer)))
                (multiple-value-bind (table prefix status)
                    (decision-fixture-read buffer start end :version version
                                           :file-offset 4294967296 :max-participants (* 5 count))
                  (is (= end prefix)) (is (eq :complete status))
                  (assert-decision-table table physical-order '(1 1024 1025))
                  (is (equalp before buffer)))))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-017
(deftest test-REQ-TXM-005-public-radix-first-physical-conflict-across-groups
  (let* ((threshold arcdocdb.recovery.decisions::+radix-entry-threshold+)
         (a (list (participant-id 0) (participant-id 1)))
         (b (list (participant-id 0) (participant-id 2)))
         (first (list (decision-spec #xffffffffffffffff 0 a) (decision-spec 0 0 a)))
         (filler (loop for i below (- threshold 2) collect (decision-spec (+ 17 i) 0 a)))
         (conflicts (list (decision-spec #xffffffffffffffff 0 b) (decision-spec 0 1 a))))
    (is (>= threshold 3))
    ;; Il gruppo TXID zero è visitato per primo nell'ordine numerico, ma il suo
    ;; record discordante è fisicamente successivo a quello del TXID massimo.
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list first filler conflicts) :version version
                                                              :file-offset 4294967296)
        (let ((before (copy-seq buffer))
              (expected (+ 4294967296 (first (getf (third layouts) :records)))))
          (dotimes (attempt 2)
            (let ((condition (signals corruption-detected
                               (decision-fixture-read buffer start end :version version
                                                      :file-offset 4294967296)
                               :decision-conflict)))
              (is (= expected (error-offset condition)))
              (is (equalp before buffer)))))))))
