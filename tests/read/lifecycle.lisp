(in-package #:arcdocdb.read.tests)

;;; REQ: REQ-MVC-005 REQ-CMP-007
(deftest test-REQ-MVC-005-read-current-buffer-untouched
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (let* ((buffer (read-words)) (before (copy-seq buffer)))
      (unwind-protect
           (progn
             (is (avvia-lettura context nil 0 10))
             (is (epoca-attiva-p reader))
             (is (null (copia-limite-lettura context buffer 1)))
             (is (equalp before buffer))
             (is (null (concludi-lettura context 11))))
        (abbandona-lettura context))
      (read-check-idle context reader))))

;;; REQ: REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-005-read-snapshot-csn-zero-carry-boxed
  (dolist (base (list 0 #xffffffff most-positive-fixnum #x8000000000000000))
    (with-read-fixture (csns snapshots snapshot epochs reader context) (:base base)
      (let* ((expected (if (zerop base) 0 (1+ base))) (buffer (read-words))
             (before (copy-seq buffer)))
        (unless (zerop base)
          (let ((token (read-take csns)))
            (is (= expected (+ (* 4294967296 (second token)) (third token))))
            (read-resolve csns token)))
        (is (equal (list 1 expected t) (multiple-value-list (registra-snapshot snapshot 10))))
        (unwind-protect
             (progn
               (is (avvia-lettura context snapshot 1 11))
               (is (copia-limite-lettura context buffer 1))
               (is (= expected (aref buffer 1)))
               (is (= (aref before 0) (aref buffer 0)))
               (is (= (aref before 2) (aref buffer 2)))
               (is (null (concludi-lettura context 12))))
          (abbandona-lettura context))
        (read-check-idle context reader)
        (termina-snapshot snapshot 1)))))

;;; REQ: REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-MVC-004-read-completion-keeps-snapshot
  (with-read-fixture (csns snapshots snapshot epochs reader context) (:base 17)
    (is (equal '(1 17 t) (multiple-value-list (registra-snapshot snapshot 10))))
    (unwind-protect
         (progn
           (is (avvia-lettura context snapshot 1 11))
           (concludi-lettura context 12)
           (read-check-idle context reader)
           (is (= 17 (verifica-snapshot snapshot 1 13)))
           (is (= 1 (nth-value 0 (leggi-registro-snapshot snapshots)))))
      (abbandona-lettura context)
      (termina-snapshot snapshot 1))))

;;; REQ: REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-MVC-004-read-waiting-refusal-cleans-epoch
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (let ((token (read-take csns)))
      (is (equal '(1 1 nil) (multiple-value-list (registra-snapshot snapshot 10))))
      (unwind-protect
           (progn
             (signals invalid-argument (avvia-lettura context snapshot 1 11) :snapshot-not-ready)
             (read-check-idle context reader)
             (signals resource-exhausted (avvia-lettura context snapshot 1 15)
                      :snapshot-wait-timeout)
             (read-check-idle context reader))
        (abbandona-lettura context)
        (termina-snapshot snapshot 1)
        (read-resolve csns token)))))

;;; REQ: REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-MVC-004-read-ended-begin-cleans-epoch
  (dolist (ended '(:expired :terminated))
    (with-read-fixture (csns snapshots snapshot epochs reader context) ()
      (is (equal '(1 0 t) (multiple-value-list (registra-snapshot snapshot 10))))
      (when (eq ended :terminated) (termina-snapshot snapshot 1))
      (unwind-protect
           (progn
             (if (eq ended :expired)
                 (signals snapshot-too-old (avvia-lettura context snapshot 1 30)
                          :snapshot-age-expired)
                 (signals snapshot-too-old (avvia-lettura context snapshot 1 11) :snapshot-ended))
             (read-check-idle context reader))
        (abbandona-lettura context)
        (termina-snapshot snapshot 1)))))

;;; REQ: REQ-CON-004 REQ-MVC-005
(deftest test-REQ-CON-004-read-current-generation-before-pin
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (signals invalid-argument (avvia-lettura context nil 1 10) :read-current-generation)
    (read-check-idle context reader)))

;;; REQ: REQ-CON-004 REQ-MVC-005
(deftest test-REQ-CON-004-read-snapshot-zero-generation-before-pin
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (registra-snapshot snapshot 10)
    (unwind-protect
         (progn
           (signals invalid-argument (avvia-lettura context snapshot 0 11) :read-snapshot-identity)
           (read-check-idle context reader))
      (termina-snapshot snapshot 1))))

;;; REQ: REQ-CON-004 REQ-MVC-005
(deftest test-REQ-CON-004-read-foreign-snapshot-before-pin
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (let* ((foreign-registry (crea-registro-snapshot csns 1 20 5))
           (foreign (crea-contesto-snapshot foreign-registry)))
      (registra-snapshot foreign 10)
      (unwind-protect
           (progn
             (signals invalid-argument (avvia-lettura context foreign 1 11) :read-snapshot-identity)
             (read-check-idle context reader))
        (termina-snapshot foreign 1)))))

;;; REQ: REQ-CON-004 REQ-CMP-007
(deftest test-REQ-CON-004-read-already-active-reader-refusal
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (is (entra-epoca reader))
    (unwind-protect
         (progn
           (signals invalid-argument (crea-contesto-lettura reader snapshots) :read-worker-busy)
           (signals invalid-argument (avvia-lettura context nil 0 10) :read-worker-busy)
           (is (epoca-attiva-p reader))
           (is (eq :idle (stato-contesto-lettura context))))
      (esci-epoca reader))
    (read-check-idle context reader)))

;;; REQ: REQ-CON-004 REQ-CMP-007
(deftest test-REQ-CON-004-read-nested-keeps-existing-pin
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (unwind-protect
         (progn
           (is (avvia-lettura context nil 0 10))
           (signals invalid-argument (avvia-lettura context nil 0 11) :read-context-not-idle)
           (is (eq :active (stato-contesto-lettura context)))
           (is (epoca-attiva-p reader))
           (concludi-lettura context 12))
      (abbandona-lettura context))
    (read-check-idle context reader)))

;;; REQ: REQ-MVC-005 REQ-CON-004
(deftest test-REQ-MVC-005-read-inactive-buffer-refusal
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (let* ((buffer (read-words)) (before (copy-seq buffer)))
      (signals invalid-argument (copia-limite-lettura context buffer 1) :read-context-not-active)
      (signals invalid-argument (concludi-lettura context 10) :read-context-not-active)
      (is (equalp before buffer))
      (read-check-idle context reader))))

;;; REQ: REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-005-read-result-range-preserves-buffer
  (dolist (snapshot-p '(nil t))
    (with-read-fixture (csns snapshots snapshot epochs reader context) (:base 11)
      (let* ((buffer (read-words)) (before (copy-seq buffer)))
        (when snapshot-p (registra-snapshot snapshot 10))
        (unwind-protect
             (progn
               (is (avvia-lettura context (when snapshot-p snapshot) (if snapshot-p 1 0) 11))
               (dolist (index '(-1 3))
                 (signals invalid-argument (copia-limite-lettura context buffer index)
                          :read-result-range)
                 (is (equalp before buffer)))
               (concludi-lettura context 12))
          (abbandona-lettura context)
          (when snapshot-p (termina-snapshot snapshot 1)))
        (read-check-idle context reader)))))

;;; REQ: REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-MVC-004-read-final-snapshot-check
  (dolist (ended '(:exact-deadline :terminated))
    (with-read-fixture (csns snapshots snapshot epochs reader context) (:base 19)
      (let ((authorized nil) (buffer (read-words)))
        (registra-snapshot snapshot 10)
        (unwind-protect
             (progn
               (is (avvia-lettura context snapshot 1 11))
               (is (copia-limite-lettura context buffer 1))
               (is (= 19 (aref buffer 1)))
               (when (eq ended :terminated) (termina-snapshot snapshot 1))
               (if (eq ended :exact-deadline)
                   (signals snapshot-too-old
                     (progn (concludi-lettura context 30) (setf authorized t)) :snapshot-age-expired)
                   (signals snapshot-too-old
                     (progn (concludi-lettura context 12) (setf authorized t)) :snapshot-ended))
               (is (null authorized))
               (read-check-idle context reader))
          (abbandona-lettura context)
          (termina-snapshot snapshot 1))))))

;;; REQ: REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-CMP-007-read-logical-expiry-keeps-live-epoch
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (multiple-value-bind (ticket retirement-generation) (prenota-ritiro epochs (vector :resource))
      (registra-snapshot snapshot 10)
      (unwind-protect
           (progn
             (is (avvia-lettura context snapshot 1 11))
             ;; Interleaving logico di manutenzione; nessuna finestra interna intercettata.
             (pubblica-ritiro ticket retirement-generation)
             (is (equal '(2 1) (multiple-value-list (scadi-snapshot snapshots 30 2))))
             (is (= 0 (nth-value 0 (leggi-registro-snapshot snapshots))))
             (is (epoca-attiva-p reader))
             (is (eq :active (stato-contesto-lettura context)))
             (aggiorna-soglia-reclaim epochs)
             (is (null (acquisisci-reclaim ticket retirement-generation)))
             (signals snapshot-too-old (concludi-lettura context 30) :snapshot-ended)
             (read-check-idle context reader)
             (aggiorna-soglia-reclaim epochs)
             (is (acquisisci-reclaim ticket retirement-generation))
             (completa-reclaim ticket retirement-generation))
        (abbandona-lettura context)
        (termina-snapshot snapshot 1)))))

;;; REQ: REQ-CON-004 REQ-CMP-007
(deftest test-REQ-CON-004-read-clock-regression-releases-pin
  (dolist (snapshot-p '(nil t))
    (dolist (finish '(9 10 11))
      (with-read-fixture (csns snapshots snapshot epochs reader context) ()
        (let ((authorized nil))
          (when snapshot-p (registra-snapshot snapshot 0))
          (unwind-protect
               (progn
                 (is (avvia-lettura context (when snapshot-p snapshot) (if snapshot-p 1 0) 10))
                 (if (< finish 10)
                     (signals invalid-argument
                       (progn (concludi-lettura context finish) (setf authorized t))
                       :read-clock-regression)
                     (progn (is (null (concludi-lettura context finish))) (setf authorized t)))
                 (is (eql authorized (>= finish 10)))
                 (read-check-idle context reader))
            (abbandona-lettura context)
            (when snapshot-p (termina-snapshot snapshot 1))))))))

;;; REQ: REQ-CMP-007 REQ-CON-004
(deftest test-REQ-CMP-007-read-abandon-releases-pin
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (unwind-protect
         (progn
           (is (avvia-lettura context nil 0 10))
           (is (epoca-attiva-p reader))
           (is (null (abbandona-lettura context)))
           (read-check-idle context reader)
           (is (null (abbandona-lettura context)))
           (read-check-idle context reader))
      (abbandona-lettura context))))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-read-idle-residual-generation (read-fi-idle-word 0))
;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-read-idle-residual-csn (read-fi-idle-word 1))
;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-read-idle-residual-start (read-fi-idle-word 2))
;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-read-idle-residual-confirmed (read-fi-idle-word 3))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-read-idle-residual-snapshot
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (setf (arcdocdb.read::contesto-lettura-snapshot context) snapshot)
    (signals invariant-violation (avvia-lettura context nil 0 10) :read-idle-data)
    (abbandona-lettura context)
    (read-check-faulted context reader)
    (is (null (arcdocdb.read::contesto-lettura-snapshot context)))))

;;; REQ: REQ-MVC-005 REQ-AFF-004
(deftest test-REQ-AFF-004-read-active-current-generation (read-fi-active-current-word 0))
;;; REQ: REQ-MVC-005 REQ-AFF-004
(deftest test-REQ-AFF-004-read-active-current-csn (read-fi-active-current-word 1))

;;; REQ: REQ-MVC-005 REQ-AFF-004
(deftest test-REQ-AFF-004-read-active-snapshot-zero-generation
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (registra-snapshot snapshot 10)
    (unwind-protect
         (progn
           (is (avvia-lettura context snapshot 1 11))
           (setf (aref (read-private-words context) 0) 0)
           (signals invariant-violation (copia-limite-lettura context (read-words) 1)
                    :read-snapshot-binding)
           (is (epoca-attiva-p reader)))
      (abbandona-lettura context)
      (termina-snapshot snapshot 1))
    (read-check-faulted context reader)))

;;; REQ: REQ-MVC-005 REQ-AFF-004
(deftest test-REQ-AFF-004-read-active-foreign-binding
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (let ((foreign (crea-contesto-snapshot (crea-registro-snapshot csns 1 20 5))))
      (registra-snapshot snapshot 10)
      (unwind-protect
           (progn
             (is (avvia-lettura context snapshot 1 11))
             (setf (arcdocdb.read::contesto-lettura-snapshot context) foreign)
             (signals invariant-violation (copia-limite-lettura context (read-words) 1)
                      :read-snapshot-binding)
             (is (epoca-attiva-p reader)))
        (abbandona-lettura context)
        (termina-snapshot snapshot 1))
      (read-check-faulted context reader))))

;;; REQ: REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-AFF-004-read-missing-epoch-fault
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (unwind-protect
         (progn
           (is (avvia-lettura context nil 0 10))
           ;; FI: il proprietario libera indebitamente l'epoca prima della conclusione.
           (esci-epoca reader)
           (signals invariant-violation (concludi-lettura context 11) :read-epoch-missing))
      (abbandona-lettura context))
    (read-check-faulted context reader)))

;;; REQ: REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-read-faulted-context-stays-faulted
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (unwind-protect
         (progn
           (is (avvia-lettura context nil 0 10))
           (setf (aref (read-private-words context) 0) 1)
           (signals invariant-violation (copia-limite-lettura context (read-words) 1)
                    :read-current-binding)
           (is (epoca-attiva-p reader)))
      (abbandona-lettura context))
    (read-check-faulted context reader)
    (is (null (abbandona-lettura context)))
    (read-check-faulted context reader)
    (signals invalid-argument (avvia-lettura context nil 0 11) :read-context-not-idle)
    (read-check-faulted context reader)))

;;; REQ: REQ-MVC-005 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-read-final-csn-changed-fault
  (with-read-fixture (csns snapshots snapshot epochs reader context) (:base 17)
    (let ((authorized nil))
      (registra-snapshot snapshot 10)
      (unwind-protect
           (progn
             (is (avvia-lettura context snapshot 1 11))
             (setf (aref (read-private-words context) 1) 18)
             (signals invariant-violation
               (progn (concludi-lettura context 12) (setf authorized t)) :read-snapshot-csn-changed)
             (is (null authorized)))
        (abbandona-lettura context)
        (termina-snapshot snapshot 1))
      (read-check-faulted context reader))))

;;; REQ: REQ-CMP-007 REQ-CON-004
(deftest test-REQ-CMP-007-read-external-error-throw-cleanup
  (dolist (exit '(:error :throw :begin-error))
    (with-read-fixture (csns snapshots snapshot epochs reader context) ()
      (let ((cleaned nil) (authorized nil) (seen nil))
        (case exit
          (:error
           (handler-case
               (unwind-protect
                    (progn (is (avvia-lettura context nil 0 10))
                           (error 'invalid-argument :reason :read-fixture-error)
                           (setf authorized t))
                 (abbandona-lettura context) (setf cleaned t))
             (invalid-argument (condition) (setf seen (error-reason condition))))
           (is (eq :read-fixture-error seen)))
          (:throw
           (setf seen
                 (catch 'read-fixture-exit
                   (unwind-protect
                        (progn (is (avvia-lettura context nil 0 10))
                               (throw 'read-fixture-exit :thrown)
                               (setf authorized t))
                     (abbandona-lettura context) (setf cleaned t))))
           (is (eq :thrown seen)))
          (:begin-error
           (handler-case
               (unwind-protect
                    (progn (avvia-lettura context nil 1 10) (setf authorized t))
                 (abbandona-lettura context) (setf cleaned t))
             (invalid-argument (condition) (setf seen (error-reason condition))))
           (is (eq :read-current-generation seen))))
        (is cleaned) (is (null authorized))
        (read-check-idle context reader)))))
