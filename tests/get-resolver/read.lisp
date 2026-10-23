;;;; Letture CLOSED con OUTCOME: aspettative wire esplicite, nessun oracolo del resolver.
;;; OWNER: un worker seriale per fixture; FI sui soli byte posseduti, ripristinata prima della chiusura.
;;; SHARED: mappa completata/FD readonly protetti dal pin GET; nessuna pubblicazione concorrente.
(in-package #:arcdocdb.get.resolver.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun resolver-read-record (&key (kind :prepared) (txid #xfedcba9876543210)
                                 (csn 7) (key-byte #x11) (value-byte #xa1))
  "Fixture esplicita: ogni PUT ha key16/value16, quindi 56 byte wire."
  (list :kind kind :txid txid :csn csn
        :key (resolver-octets 16 key-byte) :value (resolver-octets 16 value-byte)))

(defun resolver-read-operation (operation context map)
  (ecase operation
    (:resolve (r:risolvi-candidato-get context map))
    (:probe (r:sonda-cache-risolta-get context map))
    (:read (r:leggi-record-risolto-get context map))))

(defun resolver-read-output-untouched-p (fixture)
  (every (lambda (byte) (= byte #xcc)) (rf-output fixture)))

(defun resolver-read-offset-counts (fixture)
  "L'osservatore conserva il FD reale; qui si proiettano soltanto offset/count."
  (mapcar #'cdr (resolver-reads fixture)))

(defun resolver-read-same-fd-p (fixture)
  (let ((events (resolver-reads fixture)))
    (and events (every (lambda (event) (= (first event) (first (first events)))) events))))

(defun resolver-read-candidate (fixture ordinal)
  (is (eq :candidate (resolver-begin fixture ordinal)))
  (is (eq :candidate (g:stato-contesto-get (rf-context fixture))))
  (is (e:epoca-attiva-p (e:contesto-epoca (rf-epochs fixture) 0)))
  (is (resolver-read-output-untouched-p fixture)))

(defun resolver-read-refusal (fixture operation reason &optional (state :faulted))
  (let ((authorized nil))
    (signals invariant-violation
      (progn (resolver-read-operation operation (rf-context fixture) (rf-map fixture))
             (setf authorized t))
      reason)
    (is (null authorized))
    (is (resolver-clean-p fixture state))
    (is (resolver-read-output-untouched-p fixture))
    (is (null (resolver-reads fixture)))
    (signals invalid-argument (g:concludi-get (rf-context fixture) 12) :get-result-not-ready)))

(defun resolver-read-write-owned-proof (fixture offset bytes)
  "FI persistente esplicita: sovrascrive solo 32 byte del file della fixture, dopo il build."
  (is (= 32 (length bytes)))
  (with-open-file (stream (rf-path fixture) :direction :io :element-type '(unsigned-byte 8)
                          :if-exists :overwrite :if-does-not-exist :error)
    (is (file-position stream offset))
    (write-sequence bytes stream)
    (finish-output stream))
  nil)

(defmacro with-resolver-read-proof-fi ((fixture offset bytes) &body body)
  (let ((owner (gensym "OWNER")) (position (gensym "OFFSET")) (original (gensym "ORIGINAL")))
    `(let* ((,owner ,fixture) (,position ,offset)
            (,original (subseq (rf-image ,owner) ,position (+ ,position 32))))
       (unwind-protect
            (progn (resolver-read-write-owned-proof ,owner ,position ,bytes) ,@body)
         (resolver-read-write-owned-proof ,owner ,position ,original)))))

;;; REQ: REQ-FOR-004 REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-FOR-004-resolver-multiple-prepared-TXID-and-CSN-u64
  (dolist (version '(1 2))
    (with-resolver-fixture
        (f :version version :cache-p nil
           :records (list (resolver-read-record :txid #xffffffffffffffff :csn #x100000000)
                          (resolver-read-record :txid #xffffffff :csn #xffffffff :key-byte #x22)
                          (resolver-read-record :txid #x100000000 :csn #xffffffffffffffff :key-byte #x33))
           ;; Ordine fisico OUTCOME diverso dall'ordine PUT e dall'ordine TXID.
           :proofs '((:txid #x100000000 :csn #xffffffffffffffff)
                     (:txid #xffffffffffffffff :csn #x100000000)
                     (:txid #xffffffff :csn #xffffffff)))
      (dotimes (ordinal 3)
        (unwind-protect
             (progn
               (fill (rf-output f) #xcc)
               (resolver-read-candidate f ordinal)
               (multiple-value-bind (segment end flags proof)
                   (r:risolvi-candidato-get (rf-context f) (rf-map f))
                 (is (typep segment 'g:segmento-get))
                 (is (= 384 end)) ; 64 + 3*56 + 3*32 + 56.
                 (is (= 1 flags))
                 (is (= (aref #(264 296 232) ordinal) proof)))
               (let ((candidate (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))
                 (g:copia-candidato-get (rf-context f) candidate)
                 (is (= (aref #(#x100000000 #xffffffff #xffffffffffffffff) ordinal)
                        (aref candidate 0)))
                 (is (= (+ 64 (* 56 ordinal)) (ldb (byte 32 0) (aref candidate 1))))
                 (is (= 56 (aref candidate 3))))
               (is (null (resolver-reads f)))
               (is (equal '(:segment :disabled :not-attempted nil nil)
                          (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
               (is (resolver-copy-and-finish f ordinal))
               (is (equal (list (list (aref #(264 296 232) ordinal) 32)
                                      (list (+ 64 (* 56 ordinal)) 56))
                          (resolver-read-offset-counts f)))
               (is (resolver-read-same-fd-p f)))
          (g:abbandona-get (rf-context f)))
        (resolver-clear-reads f)))))

;;; REQ: REQ-FOR-004 REQ-IDX-001
(deftest test-REQ-FOR-004-resolver-TXID-high-low-boundaries
  (dolist (txid '(1 #xffffffff #x100000000 #x100000001 #xffffffffffffffff))
    (with-resolver-fixture
        (f :cache-p nil :records (list (resolver-read-record :txid txid :csn #x8000000000000001))
           :proofs (list (list :txid txid :csn #x8000000000000001)))
      (unwind-protect
           (progn
             (resolver-read-candidate f 0)
             (is (= 120 (nth-value 3 (r:risolvi-candidato-get (rf-context f) (rf-map f)))))
             (is (equal '(:segment :disabled :not-attempted nil nil)
                        (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
             (is (resolver-copy-and-finish f 0))
             (is (equal '((120 32) (64 56)) (resolver-read-offset-counts f))))
        (g:abbandona-get (rf-context f))))))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-identical-duplicates-select-first-physical-proof
  (dolist (version '(1 2))
    (with-resolver-fixture
        (f :version version :records (list (resolver-read-record :txid #x100000001 :csn #xffffffff))
           :proofs '((:txid #xffffffffffffffff :csn 7)
                     (:txid #x100000001 :csn #xffffffff)
                     (:txid #x100000001 :csn #xffffffff)
                     (:txid 1 :csn 9)))
      (unwind-protect
           (progn
             (resolver-read-candidate f 0)
             (is (= 152 (nth-value 3 (r:risolvi-candidato-get (rf-context f) (rf-map f)))))
             (is (eq :proof-required (r:sonda-cache-risolta-get (rf-context f) (rf-map f))))
             (is (null (resolver-reads f)))
             (is (equal '(:segment :miss :inserted nil nil)
                        (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
             (is (resolver-copy-and-finish f 0))
             (is (equal '((152 32) (64 56)) (resolver-read-offset-counts f))))
        (g:abbandona-get (rf-context f))))))

;;; REQ: REQ-FOR-004 REQ-CCH-002
(deftest test-REQ-FOR-004-resolver-mixed-ordinary-prepared-flags
  (with-resolver-fixture
      (f :cache-p nil
         :records (list (resolver-read-record :txid 2)
                        (resolver-read-record :kind :ordinary :csn 7 :key-byte #x22)
                        (resolver-read-record :txid #x100000002 :key-byte #x33))
         :proofs '((:txid #x100000002 :csn 7) (:txid 2 :csn 7)))
    (dotimes (ordinal 3)
      (fill (rf-output f) #xcc)
      (unwind-protect
           (progn
             (resolver-read-candidate f ordinal)
             (multiple-value-bind (segment end flags proof)
                 (r:risolvi-candidato-get (rf-context f) (rf-map f))
               (declare (ignore segment))
               (is (= 352 end))
               (is (= (aref #(1 0 1) ordinal) flags))
               (is (eql (aref #(264 nil 232) ordinal) proof)))
             (is (eq (if (= ordinal 1) :disabled :proof-required)
                     (r:sonda-cache-risolta-get (rf-context f) (rf-map f))))
             (is (null (resolver-reads f)))
             (r:leggi-record-risolto-get (rf-context f) (rf-map f))
             (is (resolver-copy-and-finish f ordinal)))
        (g:abbandona-get (rf-context f)))
      (resolver-clear-reads f))))

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-FOR-004 REQ-CMP-007
(deftest test-REQ-CCH-002-resolver-prepared-cold-read-proof-before-PUT-same-FD
  (with-resolver-fixture
      (f :records (list (resolver-read-record))
         :proofs '((:txid #xfedcba9876543210 :csn 7)))
    (unwind-protect
         (progn
           (resolver-read-candidate f 0)
           (is (eq :proof-required (r:sonda-cache-risolta-get (rf-context f) (rf-map f))))
           (is (null (resolver-reads f)))
           (is (equal '(:segment :miss :inserted nil nil)
                      (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
           (is (eq :verified (g:stato-contesto-get (rf-context f))))
           (is (resolver-read-output-untouched-p f))
           (is (equal '((120 32) (64 56)) (resolver-read-offset-counts f)))
           (is (resolver-read-same-fd-p f))
           (is (resolver-copy-and-finish f 0)))
      (g:abbandona-get (rf-context f)))))

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-FOR-004
(deftest test-REQ-CCH-002-resolver-prepared-cache-hit-still-rereads-own-proof
  (with-resolver-fixture
      (f :records (list (resolver-read-record))
         :proofs '((:txid #xfedcba9876543210 :csn 7)))
    (let ((native-fd nil))
      (unwind-protect
           (progn
             (resolver-read-candidate f 0)
             (r:leggi-record-risolto-get (rf-context f) (rf-map f))
             (setf native-fd (first (first (resolver-reads f))))
             (is (resolver-copy-and-finish f 0))
             (resolver-clear-reads f)
             (fill (rf-output f) #xcc)
             (resolver-read-candidate f 0)
             (is (eq :proof-required (r:sonda-cache-risolta-get (rf-context f) (rf-map f))))
             (is (eq :candidate (g:stato-contesto-get (rf-context f))))
             (is (null (resolver-reads f)))
             (is (equal '(:cache :hit :not-attempted nil nil)
                        (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
             (is (equal (list (list native-fd 120 32)) (resolver-reads f)))
             (is (resolver-read-output-untouched-p f))
             (is (resolver-copy-and-finish f 0)))
        (g:abbandona-get (rf-context f))))))

;;; REQ: REQ-CCH-002 REQ-FOR-004
(deftest test-REQ-CCH-002-resolver-ordinary-cache-hit-requires-no-proof-or-IO
  (with-resolver-fixture (f :records (list (resolver-read-record :kind :ordinary)) :proofs nil)
    (unwind-protect
         (progn
           (resolver-read-candidate f 0)
           (is (null (nth-value 3 (r:risolvi-candidato-get (rf-context f) (rf-map f)))))
           (is (eq :miss (r:sonda-cache-risolta-get (rf-context f) (rf-map f))))
           (is (equal '(:segment :miss :inserted nil nil)
                      (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
           (is (resolver-copy-and-finish f 0))
           (resolver-clear-reads f)
           (fill (rf-output f) #xcc)
           (resolver-read-candidate f 0)
           (is (equal '(:cache :hit :not-attempted nil nil)
                      (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
           (is (null (resolver-reads f)))
           (is (resolver-copy-and-finish f 0)))
      (g:abbandona-get (rf-context f)))))

;;; REQ: REQ-FOR-004 REQ-AFF-004 REQ-IDX-001
(deftest test-REQ-FOR-004-resolver-unresolved-prepared-cannot-authorize-response
  (dolist (operation '(:resolve :probe :read))
    (with-resolver-fixture (f :records (list (resolver-read-record)) :proofs nil)
      (unwind-protect
           (progn
             (resolver-read-candidate f 0)
             ;; Nessun OUTCOME: le word CSN della riga restano zero, senza commit inventato.
             ;; Il candidato pubblico positivo discordante viene respinto prima della prova.
             (resolver-read-refusal f operation :resolver-candidate-csn)
             (g:abbandona-get (rf-context f))
             (is (resolver-clean-p f :faulted)))
        (g:abbandona-get (rf-context f))))))

(defun resolver-read-csn-mismatch (actual)
  (dolist (operation '(:resolve :probe :read))
    (with-resolver-fixture
        (f :records (list (resolver-read-record :csn #x100000007))
           :proofs '((:txid #xfedcba9876543210 :csn #x100000007)) :candidate-csns (list actual))
      (unwind-protect
           (progn (resolver-read-candidate f 0)
                  (resolver-read-refusal f operation :resolver-candidate-csn))
        (g:abbandona-get (rf-context f))))))

;;; REQ: REQ-FOR-004 REQ-AFF-004 REQ-IDX-001
(deftest test-REQ-FOR-004-resolver-candidate-CSN-low-word-mismatch
  (resolver-read-csn-mismatch #x100000008))
;;; REQ: REQ-FOR-004 REQ-AFF-004 REQ-IDX-001
(deftest test-REQ-FOR-004-resolver-candidate-CSN-high-word-mismatch
  (resolver-read-csn-mismatch #x200000007))

;;; REQ: REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CMP-007-resolver-foreign-canonical-owner-cleans-pin
  (dolist (operation '(:resolve :probe :read))
    (with-resolver-fixture (f)
      (with-resolver-fixture (foreign)
        (unwind-protect
             (progn
               (resolver-read-candidate f 0)
               (signals invalid-argument
                 (resolver-read-operation operation (rf-context f) (rf-map foreign)) :resolver-source-owner)
               (is (resolver-clean-p f))
               (is (resolver-read-output-untouched-p f))
               (is (null (resolver-reads f)))
               (is (null (resolver-reads foreign))))
          (g:abbandona-get (rf-context f)))))))

;;; REQ: REQ-CON-004 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-CON-004-resolver-preconditions-preserve-existing-pin
  (dolist (operation '(:resolve :probe :read))
    (with-resolver-fixture (f)
      (signals invalid-argument
        (resolver-read-operation operation (rf-context f) (rf-map f)) :get-worker-state)
      (is (resolver-clean-p f))
      (unwind-protect
           (progn
             (resolver-read-candidate f 0)
             (r:leggi-record-risolto-get (rf-context f) (rf-map f))
             (signals invalid-argument
               (resolver-read-operation operation (rf-context f) (rf-map f)) :get-worker-state)
             (is (eq :verified (g:stato-contesto-get (rf-context f))))
             (is (e:epoca-attiva-p (e:contesto-epoca (rf-epochs f) 0)))
             (is (resolver-copy-and-finish f 0)))
        (g:abbandona-get (rf-context f))))))

;;; REQ: REQ-CON-004 REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-CON-004-resolver-small-buffer-precedes-prepared-proof-IO
  (with-resolver-fixture
      (f :record-bytes 55 :records (list (resolver-read-record))
         :proofs '((:txid #xfedcba9876543210 :csn 7)))
    (unwind-protect
         (progn
           (resolver-read-candidate f 0)
           (is (eq :buffer-required (r:sonda-cache-risolta-get (rf-context f) (rf-map f))))
           (is (equal '(:buffer-required :not-attempted :not-attempted nil nil)
                      (multiple-value-list (r:leggi-record-risolto-get (rf-context f) (rf-map f)))))
           (is (eq :candidate (g:stato-contesto-get (rf-context f))))
           (is (null (resolver-reads f)))
           (is (resolver-read-output-untouched-p f)))
      (g:abbandona-get (rf-context f)))
    (is (resolver-clean-p f))))

(defun resolver-read-rejects-warm-proof (proof reason expected-reads)
  "Il sensore osserva un OUTCOME cambiato sul file reale dopo mappa e cache calda."
  (with-resolver-fixture
      (f :records (list (resolver-read-record :txid #x100000001 :csn #x100000007))
         :proofs '((:txid #x100000001 :csn #x100000007)))
    (unwind-protect
         (progn
           (resolver-read-candidate f 0)
           (r:leggi-record-risolto-get (rf-context f) (rf-map f))
           (is (resolver-copy-and-finish f 0))
           (resolver-clear-reads f)
           (fill (rf-output f) #xcc)
           (with-resolver-read-proof-fi (f 120 proof)
             (resolver-read-candidate f 0)
             (let ((authorized nil))
               (signals corruption-detected
                 (progn (r:leggi-record-risolto-get (rf-context f) (rf-map f)) (setf authorized t)) reason)
               (is (null authorized)))
             (is (resolver-clean-p f))
             (is (resolver-read-output-untouched-p f))
             (is (equal expected-reads (resolver-read-offset-counts f)))
             (is (resolver-read-same-fd-p f)))
           ;; Restaurati i byte autorevoli; stesso contesto e stesso FD riutilizzabili.
           (resolver-clear-reads f)
           (resolver-read-candidate f 0)
           (r:leggi-record-risolto-get (rf-context f) (rf-map f))
           (is (resolver-copy-and-finish f 0)))
      (g:abbandona-get (rf-context f)))))

(defun resolver-read-proof (txid csn)
  (resolver-reference-record 4 0 txid (resolver-octets 0)
                             (resolver-write-le (resolver-octets 8) 0 8 csn)))

;;; REQ: REQ-FOR-003 REQ-FOR-004 REQ-CCH-002
(deftest test-REQ-FOR-004-resolver-warm-cache-cannot-hide-proof-header-CRC
  (let ((proof (resolver-read-proof #x100000001 #x100000007)))
    (setf (aref proof 0) (logxor 1 (aref proof 0)))
    (resolver-read-rejects-warm-proof proof :header-crc '((120 32)))))
;;; REQ: REQ-FOR-004 REQ-CCH-002
(deftest test-REQ-FOR-004-resolver-warm-cache-cannot-hide-proof-CSN-low
  (resolver-read-rejects-warm-proof (resolver-read-proof #x100000001 #x100000008)
                                  :get-outcome-mismatch '((120 32))))
;;; REQ: REQ-FOR-004 REQ-CCH-002
(deftest test-REQ-FOR-004-resolver-warm-cache-cannot-hide-proof-CSN-high
  (resolver-read-rejects-warm-proof (resolver-read-proof #x100000001 #x200000007)
                                  :get-outcome-mismatch '((120 32))))
;;; REQ: REQ-FOR-004 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-FOR-004-resolver-warm-cache-cannot-hide-proof-TXID-low
  (resolver-read-rejects-warm-proof (resolver-read-proof #x100000002 #x100000007)
                                  :outcome-mismatch '((120 32) (64 56))))
;;; REQ: REQ-FOR-004 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-FOR-004-resolver-warm-cache-cannot-hide-proof-TXID-high
  (resolver-read-rejects-warm-proof (resolver-read-proof #x200000001 #x100000007)
                                  :outcome-mismatch '((120 32) (64 56))))

;;; REQ: REQ-FOR-004 REQ-CCH-002
(deftest test-REQ-FOR-004-resolver-later-identical-proof-cannot-rescue-corrupt-first
  (with-resolver-fixture
      (f :records (list (resolver-read-record :txid #x100000001))
         :proofs '((:txid #x100000001 :csn 7) (:txid #x100000001 :csn 7)))
    (unwind-protect
         (progn
           (resolver-read-candidate f 0)
           (r:leggi-record-risolto-get (rf-context f) (rf-map f))
           (is (resolver-copy-and-finish f 0))
           (resolver-clear-reads f)
           (fill (rf-output f) #xcc)
           (let ((proof (resolver-read-proof #x100000001 8)))
             (with-resolver-read-proof-fi (f 120 proof)
               (resolver-read-candidate f 0)
               (is (= 120 (nth-value 3 (r:risolvi-candidato-get (rf-context f) (rf-map f)))))
               (signals corruption-detected
                 (r:leggi-record-risolto-get (rf-context f) (rf-map f)) :get-outcome-mismatch)
               (is (resolver-clean-p f))
               (is (resolver-read-output-untouched-p f))
               ;; La seconda prova valida a 152 non è una nuova autorità scelta in fallback.
               (is (equal '((120 32)) (resolver-read-offset-counts f))))))
      (g:abbandona-get (rf-context f)))))

;;; REQ: REQ-CON-004 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-CON-004-resolver-throw-during-proof-releases-pin
  (with-resolver-fixture
      (f :records (list (resolver-read-record))
         :proofs '((:txid #xfedcba9876543210 :csn 7)))
    (let ((observer (rf-observer f)))
      (unwind-protect
           (progn
             (setf (resolver-observer-hook observer)
                   (lambda (fd offset count)
                     (declare (ignore fd))
                     (when (and (= offset 120) (= count 32)) (throw 'resolver-proof-escape :escaped))))
             (resolver-read-candidate f 0)
             (is (eq :escaped
                     (catch 'resolver-proof-escape
                       (r:leggi-record-risolto-get (rf-context f) (rf-map f)) :unexpected)))
             (is (resolver-clean-p f))
             (is (resolver-read-output-untouched-p f))
             (setf (resolver-observer-hook observer) nil)
             (resolver-clear-reads f)
             (resolver-read-candidate f 0)
             (r:leggi-record-risolto-get (rf-context f) (rf-map f))
             (is (resolver-copy-and-finish f 0)))
        (setf (resolver-observer-hook observer) nil)
        (g:abbandona-get (rf-context f))))))

;;; REQ: REQ-MVC-004 REQ-MVC-005 REQ-CMP-007
(deftest test-REQ-MVC-004-resolver-snapshot-expires-after-private-prepared-copy
  (with-resolver-fixture
      (f :records (list (resolver-read-record))
         :proofs '((:txid #xfedcba9876543210 :csn 7)))
    (resolver-register-snapshot f 10)
    (unwind-protect
         (progn
           (resolver-read-candidate f 0)
           (r:leggi-record-risolto-get (rf-context f) (rf-map f))
           (is (= 19 (g:copia-valore-get (rf-context f) (rf-output f) 3)))
           (is (every (lambda (byte) (= byte #xa1)) (subseq (rf-output f) 3 19)))
           (let ((authorized nil))
             (signals snapshot-too-old
               (progn (g:concludi-get (rf-context f) 30) (setf authorized t)) :snapshot-age-expired)
             (is (null authorized)))
           (is (resolver-clean-p f))
           (is (every (lambda (byte) (= byte #xcc)) (subseq (rf-output f) 0 3)))
           (is (every (lambda (byte) (= byte #xcc)) (subseq (rf-output f) 19))))
      (g:abbandona-get (rf-context f)))))
