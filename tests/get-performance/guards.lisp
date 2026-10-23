(in-package #:arcdocdb.get.performance.tests)

;;; REQ: REQ-AFF-002 REQ-FOR-002 REQ-CMP-007
(deftest test-REQ-AFF-002-performance-prefix-boundary
  (dolist (version '(1 2))
    ;; La fine ESATTA della versione committed è ammessa, indipendentemente dalla coda del file.
    (performance-check-file-case version 256)
    (dolist (operation '(:probe :read))
      (with-get-performance-fixture (fixture :version version :value-bytes 256 :cache-p t)
        (performance-warm-cache fixture)
        (let ((context (aref (get-performance-fixture-contexts fixture) 0)))
          (unwind-protect
               (progn
                 (is (eq :candidate (performance-begin fixture)))
                 ;; Il file contiene il record completo e la cache è calda, ma
                 ;; un solo byte fuori dal prefisso deve essere rifiutato prima della cache/I/O.
                 (signals invariant-violation
                   (ecase operation
                     (:probe (g:sonda-cache-get context (get-performance-fixture-segment fixture)
                                               (1- (get-performance-fixture-valid-bytes fixture)) 0))
                     (:read (g:leggi-record-get context (get-performance-fixture-segment fixture)
                                               (1- (get-performance-fixture-valid-bytes fixture)) 0)))
                   :get-source-location)
                 (is (null (performance-read-events fixture)))
                 (performance-check-unpinned fixture 0 :faulted))
            (g:abbandona-get context)))))))

;;; REQ: REQ-AFF-002 REQ-MVC-005 REQ-CCH-002
(deftest test-REQ-AFF-002-performance-max-u64-verification
  (dolist (version '(1 2))
    (with-get-performance-fixture (fixture :version version :csn +performance-max-csn+
                                          :cache-p t :value-bytes 4096)
      (performance-warm-cache fixture)
      (performance-checked-get fixture :path :cache-record)
      (is (null (performance-read-events fixture))))
    ;; CRC corrette: ogni parola CSN deve essere confrontata contro l'indice,
    ;; anche quando lo stamp è positivo e rappresentabile soltanto come u64 pieno.
    (dolist (bit '(0 63))
      (with-get-performance-fixture
          (fixture :version version :csn +performance-max-csn+
                   :record-csn (logxor +performance-max-csn+ (ash 1 bit)) :cache-p t)
        (let ((context (aref (get-performance-fixture-contexts fixture) 0)) (authorized nil))
          (unwind-protect
               (progn
                 (is (eq :candidate (performance-begin fixture)))
                 (signals corruption-detected
                   (progn
                     (g:leggi-record-get context (get-performance-fixture-segment fixture)
                                        (get-performance-fixture-valid-bytes fixture) 0)
                     (setf authorized t))
                   :csn-mismatch)
                 (is (null authorized))
                 (is (equal '((64 56)) (performance-read-events fixture)))
                 (is (every (lambda (byte) (= byte +performance-output-sentinel+))
                            (aref (get-performance-fixture-outputs fixture) 0)))
                 (performance-check-unpinned fixture))
            (g:abbandona-get context)))))))

;;; REQ: REQ-CCH-004 REQ-AFF-002 REQ-CMP-007
(deftest test-REQ-CCH-004-performance-cache-crc-fallback
  (dolist (version '(1 2))
    (with-get-performance-fixture (fixture :version version :value-bytes 4096 :cache-p t)
      (performance-warm-cache fixture)
      (performance-corrupt-cache fixture)
      ;; L'oracolo verifica il valore completo DELLA STESSA operazione che ha
      ;; ricevuto VERIFY-FAILED, e una vera pread dalla capacità readonly.
      (performance-checked-get fixture :expected-cache :verify-failed :expected-insertion :inserted)
      (is (equal '((64 4136)) (performance-read-events fixture)))
      (performance-check-unpinned fixture))))

;;; REQ: REQ-AFF-002 REQ-CCH-004 REQ-CMP-007
(deftest test-REQ-AFF-002-performance-persistent-crc-guard
  (dolist (version '(1 2))
    (dolist (part '(:header :body))
      (with-get-performance-fixture
          (fixture :version version :cache-p t
                   :image-mutator
                   (lambda (image)
                     (let ((offset (if (eq part :header) 80 104)))
                       (setf (aref image offset) (logxor 1 (aref image offset))))))
        (let ((context (aref (get-performance-fixture-contexts fixture) 0)) (authorized nil))
          ;; Il guasto è persistente su due operazioni nuove: non un miss cache.
          (dotimes (attempt 2)
            (performance-clear-read-events fixture)
            (unwind-protect
                 (progn
                   (is (eq :candidate (performance-begin fixture)))
                   (signals corruption-detected
                     (progn
                       (g:leggi-record-get context (get-performance-fixture-segment fixture)
                                          (get-performance-fixture-valid-bytes fixture) 0)
                       (setf authorized t))
                     (if (eq part :header) :header-crc :body-crc))
                   (is (null authorized))
                   (is (equal '((64 56)) (performance-read-events fixture)))
                   (is (every (lambda (byte) (= byte +performance-output-sentinel+))
                              (aref (get-performance-fixture-outputs fixture) 0)))
                   (performance-check-unpinned fixture))
              (g:abbandona-get context))))))))

;;; REQ: REQ-CMP-007 REQ-CON-004 REQ-AFF-002
(deftest test-REQ-CMP-007-performance-cleanup
  (dolist (exit '(:throw :error))
    (dolist (stage '(:candidate :verified :copied))
      (with-get-performance-fixture (fixture :value-bytes 256)
        (let ((context (aref (get-performance-fixture-contexts fixture) 0)) (authorized nil)
              (output (aref (get-performance-fixture-outputs fixture) 0)) (seen nil))
          (flet ((interrupted-operation ()
                   (unwind-protect
                        (progn
                          (is (eq :candidate (performance-begin fixture)))
                          (unless (eq stage :candidate)
                            (g:leggi-record-get context (get-performance-fixture-segment fixture)
                                               (get-performance-fixture-valid-bytes fixture) 0)
                            (is (eq :verified (g:stato-contesto-get context))))
                          (when (eq stage :copied)
                            (g:copia-valore-get context output +performance-output-start+)
                            (performance-check-response fixture output))
                          (ecase exit
                            (:throw (throw 'performance-exit :interrupted))
                            (:error (error 'invalid-argument :reason :performance-injected-error)))
                          (g:concludi-get context 12)
                          (setf authorized t))
                     (g:abbandona-get context))))
            (ecase exit
              (:throw (setf seen (catch 'performance-exit (interrupted-operation)))
                      (is (eq :interrupted seen)))
              (:error (handler-case (interrupted-operation)
                        (invalid-argument (condition) (setf seen (error-reason condition))))
                      (is (eq :performance-injected-error seen)))))
          (is (null authorized))
          (performance-check-unpinned fixture)
          ;; Nuova operazione dopo il cleanup: nessuna location o stato stale.
          (performance-checked-get fixture))))))

;;; REQ: REQ-CCH-004 REQ-CCH-002 REQ-AFF-002
(deftest test-REQ-CCH-004-performance-cache-repair-hit
  ;; Dopo il fallback, la copia verificata reinserita deve essere raggiungibile
  ;; anche se una vecchia copia col medesimo tag è rifiutata o disabilitata.
  (dolist (version '(1 2))
    (with-get-performance-fixture (fixture :version version :value-bytes 4096 :cache-p t)
      (performance-warm-cache fixture)
      (performance-corrupt-cache fixture)
      (performance-checked-get fixture :expected-cache :verify-failed :expected-insertion :inserted)
      (is (equal '((64 4136)) (performance-read-events fixture)))
      (performance-clear-read-events fixture)
      (performance-checked-get fixture :path :cache-record)
      (is (null (performance-read-events fixture)))
      ;; FI esclusiva, dopo il GET concluso: tag vecchio lasciato al suo posto.
      (let* ((class (aref (c::cache-serie-classes (get-performance-fixture-cache fixture)) 0))
             (old (position 1 (c::classe-cache-rejected class))))
        (is old)
        (setf (aref (c::classe-cache-disabled class) old) 1
              (aref (c::classe-cache-rejected class) old) 0))
      (performance-checked-get fixture :path :cache-record)
      (is (null (performance-read-events fixture)))
      (performance-check-unpinned fixture))))
