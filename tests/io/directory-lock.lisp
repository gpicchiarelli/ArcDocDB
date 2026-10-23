;;;; C4: esclusiva M1 sul FD, callback locali e due aperture native indipendenti.
;;; OWNER: fixture seriali; tutte le capacita' sono chiuse prima di rmdir della root privata.
;;; SHARED: nessun override globale, worker, lockfile o nuovo formato di storage.
(in-package #:arcdocdb.io.tests)
(declaim (optimize (safety 3) (debug 3)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function () null)
                test-REQ-AFF-001-IO-DIRECTORY-LOCK-success-exact-fd-and-close-once
                test-REQ-AFF-001-IO-DIRECTORY-LOCK-busy-preserves-parent-no-retry
                test-REQ-AFF-004-IO-DIRECTORY-LOCK-errno-provenance-without-retry
                test-REQ-AFF-004-IO-DIRECTORY-LOCK-rejects-every-nonzero-or-noninteger-result
                test-REQ-AFF-008-IO-DIRECTORY-LOCK-missing-callback-no-native-fallback
                test-REQ-AFF-008-IO-DIRECTORY-LOCK-wrong-mode-before-callback-or-support-check
                test-REQ-AFF-001-IO-DIRECTORY-LOCK-closed-or-faulted-before-callback
                test-REQ-AFF-008-IO-DIRECTORY-LOCK-invalid-fd-before-callback
                test-REQ-AFF-001-IO-DIRECTORY-LOCK-callback-invalidates-parent-no-success
                test-REQ-AFF-004-IO-DIRECTORY-LOCK-preserves-typed-callback-condition))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((or null function) cons arcdocdb.io::fd) arcdocdb.io:backend)
                directory-lock-test-backend))
(defun directory-lock-test-backend (callback events descriptor)
  "Pre: cella eventi privata e FD virtuale valido. Post: solo open/lock/close ammessi."
  (make-backend
   (lambda (name mode) (declare (ignore name))
     (push (list :open descriptor mode) (car events)) descriptor)
   #'unexpected-read #'unexpected-write #'unexpected-write #'unexpected-write
   (lambda (fd) (is (= descriptor fd)) (push (list :close fd) (car events)) 0)
   :directory-lock (when callback
                     (lambda (fd) (push (list :lock fd) (car events)) (funcall callback fd)))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function ((or null function) function
                          &key (:mode (member :input :append :directory)) (:descriptor arcdocdb.io::fd))
                         null) directory-lock-test-case))
(defun directory-lock-test-case (callback thunk &key (mode :directory) (descriptor 7))
  "Pre: callback/thunk privati. Post: capacita' fake chiusa, anche dopo un assert fallito."
  (let* ((events (list nil))
         (backend (directory-lock-test-backend callback events descriptor))
         (file (ecase mode
                 (:directory (apri-directory "/directory-lock-fixture" :backend backend))
                 (:input (apri-lettura "/directory-lock-fixture" :backend backend))
                 (:append (crea-temporaneo "/directory-lock-fixture.tmp" :backend backend)))))
    (setf (arcdocdb.io::file-written file) 23 (arcdocdb.io::file-durable file) 17)
    (unwind-protect (funcall thunk file events) (chiudi file)))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (arcdocdb.io:file-io &optional (member :open :faulted :closed)
                                              arcdocdb.io::fd) null) directory-lock-test-check))
(defun directory-lock-test-check (file &optional (state :open) (descriptor 7))
  "Pre: capacita' della fixture. Post: stato, FD e frontiere invariati verificati."
  (is (eq state (stato-file file)))
  (is (= descriptor (arcdocdb.io::file-fd file)))
  (is (= 23 (posizione-scritta file))) (is (= 17 (posizione-durevole file)))
  nil)

;;; REQ: REQ-AFF-004
(declaim (ftype (function (function keyword (or null fixnum)) io-fault) directory-lock-test-fault))
(defun directory-lock-test-fault (thunk reason errno)
  "Pre: chiamata che deve fallire. Post: IO-FAULT con provenienza completa, senza cleanup inventato."
  (handler-case (progn (funcall thunk) (error "Guasto directory-lock atteso."))
    (io-fault (condition)
      (is (eq reason (error-reason condition)))
      (is (eq :directory-lock (error-operation condition)))
      (is (eql errno (error-errno condition)))
      (is (zerop (error-transferred condition)))
      (is (null (arcdocdb.conditions:error-cleanup-errno condition)))
      condition)))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-IO-DIRECTORY-LOCK-success-exact-fd-and-close-once
  "Zero intero e FD 0 ammessi; nessun altro effetto prima della close esplicita."
  (dolist (descriptor '(0 7 2147483647))
    (directory-lock-test-case
     (lambda (fd) (is (= descriptor fd)) 0)
     (lambda (file events)
       (is (equal '(nil) (multiple-value-list (arcdocdb.io:esigi-esclusiva-directory file))))
       (directory-lock-test-check file :open descriptor)
       (is (equal (list (list :lock descriptor) (list :open descriptor :directory)) (car events)))
       (chiudi file) (chiudi file)
       (directory-lock-test-check file :closed descriptor)
       (is (equal (list (list :close descriptor) (list :lock descriptor)
                        (list :open descriptor :directory)) (car events))))
     :descriptor descriptor)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-001-IO-DIRECTORY-LOCK-busy-preserves-parent-no-retry
  "Busy non guasta il parent; una nuova richiesta esplicita puo' poi acquisire il lock."
  (dolist (errno (remove-duplicates (list sb-posix:eagain sb-posix:ewouldblock)))
    (let ((busy t))
      (directory-lock-test-case
       (lambda (fd) (declare (ignore fd))
         (if busy (error 'sb-posix:syscall-error :errno errno :name 'flock) 0))
       (lambda (file events)
         (directory-lock-test-fault (lambda () (arcdocdb.io:esigi-esclusiva-directory file))
                                    :io-syscall errno)
         (directory-lock-test-check file)
         (is (equal '((:lock 7) (:open 7 :directory)) (car events)))
         (setf busy nil)
         (is (null (arcdocdb.io:esigi-esclusiva-directory file)))
         (directory-lock-test-check file)
         (is (equal '((:lock 7) (:lock 7) (:open 7 :directory)) (car events))))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-IO-DIRECTORY-LOCK-errno-provenance-without-retry
  "EINTR e guasti diversi da busy restano dichiarati con l'errno originario."
  (dolist (errno (list sb-posix:eintr sb-posix:eio sb-posix:ebadf))
    (directory-lock-test-case
     (raises-errno errno)
     (lambda (file events)
       (directory-lock-test-fault (lambda () (arcdocdb.io:esigi-esclusiva-directory file))
                                  :io-syscall errno)
       (directory-lock-test-check file)
       (is (equal '((:lock 7) (:open 7 :directory)) (car events)))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-IO-DIRECTORY-LOCK-rejects-every-nonzero-or-noninteger-result
  "NIL, boolean, float zero e risultati non POSIX non certificano l'esclusiva."
  (dolist (result '(nil t -1 1 0.0 0.0d0 1/2 :invalid))
    (directory-lock-test-case
     (lambda (fd) (declare (ignore fd)) result)
     (lambda (file events)
       (directory-lock-test-fault (lambda () (arcdocdb.io:esigi-esclusiva-directory file))
                                  :io-directory-lock-result nil)
       (directory-lock-test-check file)
       (is (equal '((:lock 7) (:open 7 :directory)) (car events)))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-DIRECTORY-LOCK-missing-callback-no-native-fallback
  "Il costruttore legacy resta valido; assenza del callback rifiutata prima di flock."
  (is (null (arcdocdb.io::backend-directory-lock (backend))))
  (directory-lock-test-case
   nil
   (lambda (file events)
     (signals arcdocdb.conditions:unsupported-format
       (arcdocdb.io:esigi-esclusiva-directory file) :io-directory-lock-unavailable)
     (directory-lock-test-check file)
     (is (equal '((:open 7 :directory)) (car events))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-DIRECTORY-LOCK-wrong-mode-before-callback-or-support-check
  "Entrambi i modi file rifiutati anche se manca il callback opzionale."
  (dolist (mode '(:input :append))
    (dolist (callback (list nil #'succeeds))
      (directory-lock-test-case
       callback
       (lambda (file events)
         (signals invalid-argument (arcdocdb.io:esigi-esclusiva-directory file) :io-mode)
         (directory-lock-test-check file)
         (is (equal (list (list :open 7 mode)) (car events))))
       :mode mode))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-IO-DIRECTORY-LOCK-closed-or-faulted-before-callback
  "Un parent non aperto non arriva al callback ne' al fallback o alla verifica del supporto."
  (dolist (state '(:closed :faulted))
    (dolist (callback (list nil #'succeeds))
      (directory-lock-test-case
       callback
       (lambda (file events)
         (if (eq state :closed) (chiudi file) (setf (arcdocdb.io::file-state file) :faulted))
         (let ((before (copy-tree (car events))))
           (signals io-fault (arcdocdb.io:esigi-esclusiva-directory file) :io-unavailable)
           (is (equal before (car events))))
         (directory-lock-test-check file state))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-IO-DIRECTORY-LOCK-invalid-fd-before-callback
  "La sentinella -1 del file-io non puo' raggiungere flock, anche senza callback."
  (dolist (callback (list nil #'succeeds))
    (directory-lock-test-case
     callback
     (lambda (file events)
       (unwind-protect
            (progn
              (setf (arcdocdb.io::file-fd file) -1)
              (signals invariant-violation (arcdocdb.io:esigi-esclusiva-directory file) :io-descriptor)
              (is (equal '((:open 7 :directory)) (car events))))
         (setf (arcdocdb.io::file-fd file) 7))
       (directory-lock-test-check file)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-IO-DIRECTORY-LOCK-callback-invalidates-parent-no-success
  "Il ritorno zero non basta se il callback ha chiuso o guastato la capacita'."
  (dolist (state '(:closed :faulted))
    (let ((target nil))
      (directory-lock-test-case
       (lambda (fd) (declare (ignore fd))
         (if (eq state :closed) (chiudi target) (setf (arcdocdb.io::file-state target) :faulted)) 0)
       (lambda (file events)
         (setf target file)
         (signals io-fault (arcdocdb.io:esigi-esclusiva-directory file) :io-unavailable)
         (directory-lock-test-check file state)
         (is (= 1 (count :lock (car events) :key #'first)))
         (is (= (if (eq state :closed) 1 0) (count :close (car events) :key #'first))))))))

;;; REQ: REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-AFF-004-IO-DIRECTORY-LOCK-preserves-typed-callback-condition
  "Le condizioni di dipendenza gia' tipizzate non perdono identita' o provenienza."
  (dolist (original (list (make-condition 'resource-exhausted :reason :directory-lock-probe)
                         (make-condition 'io-fault :reason :directory-lock-probe :operation :read
                                                  :errno sb-posix:eio :transferred 3)))
    (directory-lock-test-case
     (lambda (fd) (declare (ignore fd)) (error original))
     (lambda (file events)
       (is (eq original
               (handler-case (arcdocdb.io:esigi-esclusiva-directory file)
                 (arcdocdb.conditions:arcdocdb-error (condition) condition))))
       (directory-lock-test-check file)
       (is (equal '((:lock 7) (:open 7 :directory)) (car events)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
#+(or darwin linux)
(declaim (ftype (function () null)
                test-REQ-AFF-001-IO-DIRECTORY-LOCK-NATIVE-two-opens-busy-close-reacquire))
;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
#+(or darwin linux)
(deftest test-REQ-AFF-001-IO-DIRECTORY-LOCK-NATIVE-two-opens-busy-close-reacquire
  "Due open dello stesso inode confliggono; close libera il lock, senza nomi aggiuntivi."
  (let ((root (fresh-directory)))
    (unwind-protect
         (sb-ext:with-timeout 5
           (with-file (first (apri-directory root))
             (with-file (second (apri-directory root))
               (is (/= (arcdocdb.io::file-fd first) (arcdocdb.io::file-fd second)))
               (is (null (arcdocdb.io:esigi-esclusiva-directory first)))
               (is (zerop (length (arcdocdb.io:elenca-directory first))))
               (directory-lock-test-fault (lambda () (arcdocdb.io:esigi-esclusiva-directory second))
                                          :io-syscall sb-posix:ewouldblock)
               (is (eq :open (stato-file first))) (is (eq :open (stato-file second)))
               (is (zerop (posizione-scritta second))) (is (zerop (posizione-durevole second)))
               (chiudi first)
               (is (null (arcdocdb.io:esigi-esclusiva-directory second)))
               (is (zerop (length (arcdocdb.io:elenca-directory second))))
               (signals io-fault (arcdocdb.io:esigi-esclusiva-directory first) :io-unavailable)
               (with-file (third (apri-directory root))
                 ;; Una close ripetuta della vecchia capacita' non sblocca il nuovo owner.
                 (chiudi first)
                 (directory-lock-test-fault (lambda () (arcdocdb.io:esigi-esclusiva-directory third))
                                            :io-syscall sb-posix:ewouldblock)
                 (chiudi second)
                 (is (null (arcdocdb.io:esigi-esclusiva-directory third)))
                 (is (zerop (length (arcdocdb.io:elenca-directory third))))))))
      (sb-posix:rmdir (namestring root))))
  nil)
