;;;; Letture ACTIVE: offset e valori attesi dal piano della fixture, non dal resolver.
;;; OWNER: un compito GET seriale; FI sul candidato e callback I/O esclusivi del test.
;;; SHARED: pagine pubblicate immutabili; FD nativi conservati fino al rilascio EBR.
(in-package #:arcdocdb.get.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun active-read-operation (operation context source)
  (ecase operation
    (:resolve (r:risolvi-candidato-attivo-get context source))
    (:probe (r:sonda-cache-attiva-get context source))
    (:read (r:leggi-record-attivo-get context source))))

(defun active-read-clean-p (context epoch &optional (state :idle))
  "Witness locale osservato PRIMA del cleanup esterno; non determina esiti o frontiere."
  (and (eq state (g:stato-contesto-get context))
       (not (e:epoca-attiva-p epoch))
       (null (g::contesto-get-view context)) (null (g::contesto-get-key context))
       (not (g::contesto-get-snapshot-p context))
       (zerop (g::contesto-get-value-start context))
       (zerop (g::contesto-get-value-end context))
       (every #'zerop (g::contesto-get-content context))
       (every #'zerop (g::contesto-get-limit context))))

(defun active-read-output-untouched-p (output)
  (every (lambda (byte) (= byte #xcc)) output))

(defun active-read-check-output (output expected)
  "Output a offset tre, con sentinelle prima e dopo il valore privato."
  (is (loop for i below 3 always (= #xcc (aref output i))))
  (is (loop for byte across expected for i from 3 always (= byte (aref output i))))
  (is (loop for i from (+ 3 (length expected)) below (length output)
            always (= #xcc (aref output i))))
  t)

(defun active-read-copy-and-finish (context epoch output expected &optional (now 12))
  "Nessun oracolo dal grafo ACTIVE: EXPECTED proviene dai byte dichiarati dal test."
  (is (eq :verified (g:stato-contesto-get context)))
  (is (e:epoca-attiva-p epoch))
  (is (active-read-output-untouched-p output))
  (is (= (+ 3 (length expected)) (g:copia-valore-get context output 3)))
  (is (eq :copied (g:stato-contesto-get context)))
  (is (e:epoca-attiva-p epoch))
  (is (active-read-check-output output expected))
  (is (equal (list :found (length expected))
             (multiple-value-list (g:concludi-get context now))))
  (is (active-read-clean-p context epoch))
  t)

(defun active-read-bytes (count byte)
  (make-array count :element-type '(unsigned-byte 8) :initial-element byte))

(defun active-read-put (key value &optional (flags 0))
  (list :kind :put :key key :value value :flags flags))

(defun active-read-epoch (fixture &optional (worker 0))
  (e:contesto-epoca (af-epochs fixture) worker))

(defun active-read-reset (fixture)
  (fill (af-output fixture) #xcc)
  (active-clear-reads fixture))

(defun active-read-start (fixture ordinal &optional (worker 0))
  (is (eq :candidate (active-begin fixture ordinal :worker worker :snapshot-p nil)))
  (let ((context (aref (af-contexts fixture) worker)))
    (is (eq :candidate (g:stato-contesto-get context)))
    (is (e:epoca-attiva-p (active-read-epoch fixture worker)))
    (is (active-read-output-untouched-p (af-output fixture))))
  t)

(defun active-read-offset-counts (fixture)
  "L'osservatore registra richieste pread sul FD reale; non determina gli offset attesi."
  (mapcar #'cdr (active-reads fixture)))

(defun active-read-on-input-p (fixture)
  (let ((fd (io::file-fd (af-input fixture))))
    (every (lambda (event) (= fd (first event))) (active-reads fixture))))

(defun active-read-location-fi (context offset)
  "FI del solo offset nel candidato già copiato, conservando il segmento canonico."
  (let ((content (g::contesto-get-content context)))
    (setf (aref content 1) (+ (logand (aref content 1) #xffffffff00000000) offset))))

(defun active-read-remove-candidate-fi (fixture ordinal)
  "Rimuove pubblicamente la sola FI prima del normale cleanup root/primary."
  (let ((index (af-index fixture)) (key (aref (af-keys fixture) ordinal)))
    (multiple-value-bind (high low) (p:digest-chiave-indice index key 0 (length key))
      (is (p:rimuovi-chiave-indice index (p:frammento-corrente-indice index high)
                                  key 0 (length key) high low (p:crea-contesto-indice)))))
  t)

(defun active-read-fault (fixture operation reason)
  (let ((context (af-context fixture)) (authorized nil))
    (signals invariant-violation
      (progn (active-read-operation operation context (af-source fixture))
             (setf authorized t))
      reason)
    (is (null authorized))
    (is (active-read-clean-p context (active-read-epoch fixture) :faulted))
    (is (active-read-output-untouched-p (af-output fixture)))
    (is (null (active-reads fixture)))
    (signals invalid-argument (g:concludi-get context 12) :get-result-not-ready)))

;;; REQ: REQ-FOR-002 REQ-FOR-003 REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-FOR-003-active-native-v1-v2-CSN-u64-and-ordinary-flags
  (dolist (version '(1 2))
    (let* ((first-key (active-read-bytes 16 #x11))
           (second-key (active-read-bytes 16 #x22))
           (first-value (active-read-bytes 16 #xa1))
           (second-value (active-read-bytes 16 #xb2)))
      (with-active-fixture
          (f :version version :cache-p nil :base #x1ffffffff
             :batches (list (list (active-read-put first-key first-value 0))
                            (list (active-read-put second-key second-value 4))))
        ;; Ogni PUT = 24 + key16 + value16; ogni lotto aggiunge SEAL56.
        (dotimes (ordinal 2)
          (let ((context (af-context f))
                (expected (if (zerop ordinal) first-value second-value)))
            (unwind-protect
                 (progn
                   (active-read-reset f)
                   (active-read-start f ordinal)
                   (is (= (+ #x200000000 ordinal)
                          (aref (g::contesto-get-content context) 0)))
                   (multiple-value-bind (segment end flags proof)
                       (r:risolvi-candidato-attivo-get context (af-source f))
                     (is (eq segment (af-segment f)))
                     (is (= (aref #(176 288) ordinal) end))
                     (is (= (aref #(0 4) ordinal) flags))
                     (is (null proof)))
                   (is (eq :disabled (r:sonda-cache-attiva-get context (af-source f))))
                   (is (null (active-reads f)))
                   (is (equal '(:segment :disabled :not-attempted nil nil)
                              (multiple-value-list (r:leggi-record-attivo-get context (af-source f)))))
                   (is (equal (list (list (aref #(64 176) ordinal) 56))
                              (active-read-offset-counts f)))
                   (is (active-read-on-input-p f))
                   (active-read-copy-and-finish context (active-read-epoch f) (af-output f) expected))
              (g:abbandona-get context))))))))

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-WAL-006 REQ-CMP-007
(deftest test-REQ-CCH-002-active-cold-read-and-warm-probe-and-read
  (let ((key (active-read-bytes 16 #x31)) (value (active-read-bytes 16 #xc3)))
    (with-active-fixture (f :cache-p t :batches (list (list (active-read-put key value))))
      (let ((context (af-context f)))
        (unwind-protect
             (progn
               (active-read-reset f)
               (active-read-start f 0)
               (is (eq :miss (r:sonda-cache-attiva-get context (af-source f))))
               (is (eq :candidate (g:stato-contesto-get context)))
               (is (null (active-reads f)))
               (is (equal '(:segment :miss :inserted nil nil)
                          (multiple-value-list (r:leggi-record-attivo-get context (af-source f)))))
               (is (equal '((64 56)) (active-read-offset-counts f)))
               (is (active-read-on-input-p f))
               (active-read-copy-and-finish context (active-read-epoch f) (af-output f) value)
               (active-read-reset f)
               (active-read-start f 0)
               (is (eq :hit (r:sonda-cache-attiva-get context (af-source f))))
               (is (null (active-reads f)))
               (active-read-copy-and-finish context (active-read-epoch f) (af-output f) value)
               (active-read-reset f)
               (active-read-start f 0)
               (is (equal '(:cache :hit :not-attempted nil nil)
                          (multiple-value-list (r:leggi-record-attivo-get context (af-source f)))))
               (is (null (active-reads f)))
               (active-read-copy-and-finish context (active-read-epoch f) (af-output f) value))
          (g:abbandona-get context))))))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-WAL-006-active-durable-planned-root-cannot-authorize-value
  (dolist (operation '(:resolve :probe :read))
    (with-active-fixture (f :publish-count 0 :cache-p nil)
      (let ((context (af-context f)) (early-candidate nil))
        (unwind-protect
             (progn
               (is (null (s:leggi-radice-serie (af-controller f))))
               (is (typep (s::controllore-serie-planned-root (af-controller f)) 'r:radice-get-attiva))
               (is (>= (io:posizione-durevole (af-append f)) 176))
               ;; FI esplicita dell'ordine primary/pagina: candidato osservabile troppo presto.
               (active-publish-candidate f 0)
               (setf early-candidate t)
               (active-read-reset f)
               (active-read-start f 0)
               (active-read-fault f operation :active-published-root))
          (g:abbandona-get context)
          (when early-candidate (active-read-remove-candidate-fi f 0)))))))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-STO-006
(deftest test-REQ-WAL-006-active-old-PUT-uses-own-page-end
  (let* ((keys (vector (active-read-bytes 16 #x41) (active-read-bytes 16 #x42)
                       (active-read-bytes 16 #x43)))
         (values (vector (active-read-bytes 16 #xd1) (active-read-bytes 16 #xd2)
                         (active-read-bytes 16 #xd3))))
    (with-active-fixture
        (f :cache-p nil
           :batches (list (list (active-read-put (aref keys 0) (aref values 0)))
                          (list (active-read-put (aref keys 1) (aref values 1))
                                (active-read-put (aref keys 2) (aref values 2)))))
      (dotimes (ordinal 3)
        (let ((context (af-context f)))
          (unwind-protect
               (progn
                 (active-read-reset f)
                 (active-read-start f ordinal)
                 (is (= 344 (r::radice-get-attiva-end (s:leggi-radice-serie (af-controller f)))))
                 (multiple-value-bind (segment end flags proof)
                     (r:risolvi-candidato-attivo-get context (af-source f))
                   (is (eq segment (af-segment f)))
                   (is (= (aref #(176 344 344) ordinal) end))
                   (is (zerop flags)) (is (null proof)))
                 (is (null (active-reads f)))
                 (is (equal '(:segment :disabled :not-attempted nil nil)
                            (multiple-value-list (r:leggi-record-attivo-get context (af-source f)))))
                 (is (equal (list (list (aref #(64 176 232) ordinal) 56))
                            (active-read-offset-counts f)))
                 (active-read-copy-and-finish context (active-read-epoch f)
                                              (af-output f) (aref values ordinal)))
            (g:abbandona-get context)))))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-IDX-001-active-header-SEAL-tombstone-frontier-and-missing-row-fault
  ;; PUT64..120, TOMBSTONE120..160, SEAL160..216: nessun offset diverso dal PUT autorizza ABSENT.
  (dolist (entry '((0 :active-location-frontier) (63 :active-location-frontier)
                   (65 :resolver-location-absent) (120 :resolver-location-absent)
                   (160 :resolver-location-absent) (215 :resolver-location-absent)
                   (216 :active-location-frontier) (217 :active-location-frontier)))
    (dolist (operation '(:resolve :probe :read))
      (with-active-fixture
          (f :cache-p nil
             :batches (list (list (active-read-put (active-read-bytes 16 #x51)
                                                   (active-read-bytes 16 #xe1))
                                  (list :kind :tombstone :key (active-read-bytes 16 #x52)
                                        :value (active-read-bytes 0 0)))))
        (let ((context (af-context f)))
          (unwind-protect
               (progn
                 (active-read-reset f)
                 (active-read-start f 0)
                 (active-read-location-fi context (first entry))
                 (active-read-fault f operation (second entry)))
            (g:abbandona-get context)))))))

;;; REQ: REQ-IDX-001 REQ-FOR-003 REQ-AFF-004
(deftest test-REQ-IDX-001-active-candidate-CSN-low-and-high-word-mismatch
  (dolist (delta '(1 #x100000000))
    (dolist (operation '(:resolve :probe :read))
      (with-active-fixture (f :cache-p nil :base #x100000000)
        (let ((context (af-context f)))
          (unwind-protect
               (progn
                 (active-read-reset f)
                 (active-read-start f 0)
                 (is (= #x100000001 (aref (g::contesto-get-content context) 0)))
                 (setf (aref (g::contesto-get-content context) 0) (logxor #x100000001 delta))
                 (active-read-fault f operation :resolver-candidate-csn))
            (g:abbandona-get context)))))))

;;; REQ: REQ-IDX-001 REQ-FOR-003 REQ-AFF-004
(deftest test-REQ-IDX-001-active-candidate-wire-size-and-reserved-high-word
  (dolist (size '(55 57 #x100000038))
    (dolist (operation '(:resolve :probe :read))
      (with-active-fixture (f :cache-p nil)
        (let ((context (af-context f)))
          (unwind-protect
               (progn
                 (active-read-reset f)
                 (active-read-start f 0)
                 (is (= 56 (aref (g::contesto-get-content context) 3)))
                 (setf (aref (g::contesto-get-content context) 3) size)
                 (active-read-fault f operation :resolver-candidate-size))
            (g:abbandona-get context)))))))

;;; REQ: REQ-CMP-007 REQ-CON-004
(deftest test-REQ-CMP-007-active-foreign-source-owner-cleans-before-outer-unwind
  (dolist (operation '(:resolve :probe :read))
    (with-active-fixture (f :cache-p nil)
      (with-active-fixture (foreign :cache-p nil)
        (let ((context (af-context f)) (authorized nil))
          (unwind-protect
               (progn
                 (active-read-reset f)
                 (active-read-start f 0)
                 (signals invalid-argument
                   (progn (active-read-operation operation context (af-source foreign))
                          (setf authorized t))
                   :active-source-owner)
                 (is (null authorized))
                 (is (active-read-clean-p context (active-read-epoch f)))
                 (is (active-read-output-untouched-p (af-output f)))
                 (is (null (active-reads f)))
                 (is (null (active-reads foreign)))
                 (signals invalid-argument (g:concludi-get context 12) :get-result-not-ready))
            (g:abbandona-get context)))))))

;;; REQ: REQ-CMP-007 REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-CMP-007-active-closed-readonly-FD-is-terminal-source-fault
  (dolist (operation '(:resolve :probe :read))
    (with-active-fixture (f :cache-p nil)
      (let ((context (af-context f)))
        (unwind-protect
             (progn
               (active-read-reset f)
               (active-read-start f 0)
               (io:chiudi (af-input f))
               (active-read-fault f operation :resolver-source-lifetime))
          (g:abbandona-get context))))))

;;; REQ: REQ-CON-004 REQ-AFF-003 REQ-CMP-007
(deftest test-REQ-CON-004-active-throw-at-native-pread-cleans-without-authorizing
  (with-active-fixture (f :cache-p nil)
    (let ((context (af-context f)) (authorized nil))
      (unwind-protect
           (progn
             (active-read-reset f)
             (active-read-start f 0)
             (active-set-read-hook
              f (lambda (fd buffer start count offset)
                  (declare (ignore buffer start))
                  (is (= fd (io::file-fd (af-input f))))
                  (is (= 64 offset)) (is (= 56 count))
                  (throw 'active-read-interruption :escaped)))
             (is (eq :escaped
                     (catch 'active-read-interruption
                       (r:leggi-record-attivo-get context (af-source f))
                       (setf authorized t)
                       :returned)))
             (is (null authorized))
             (is (active-read-clean-p context (active-read-epoch f)))
             (is (active-read-output-untouched-p (af-output f)))
             ;; Richiesta osservata prima del callback; il throw precede la syscall nativa.
             (is (equal '((64 56)) (active-read-offset-counts f)))
             (signals invalid-argument (g:concludi-get context 12) :get-result-not-ready))
        (active-set-read-hook f nil)
        (g:abbandona-get context)))))

;;; REQ: REQ-CON-004 REQ-AFF-008 REQ-WAL-006 REQ-CMP-007
(deftest test-REQ-CON-004-active-small-buffer-restarts-and-reacquires-new-root
  (let ((key (active-read-bytes 16 #x61))
        (old-value (active-read-bytes 16 #xf1))
        (new-value (active-read-bytes 16 #xf2)))
    (with-active-fixture
        (f :cache-p nil :contexts 2 :record-bytes '(55 128) :publish-count 1
           :batches (list (list (active-read-put key old-value))
                          (list (active-read-put (copy-seq key) new-value))))
      (let ((small (aref (af-contexts f) 0)) (large (aref (af-contexts f) 1)))
        (unwind-protect
             (progn
               (active-read-reset f)
               (active-read-start f 0)
               (is (eq :buffer-required (r:sonda-cache-attiva-get small (af-source f))))
               (is (equal '(:buffer-required :not-attempted :not-attempted nil nil)
                          (multiple-value-list (r:leggi-record-attivo-get small (af-source f)))))
               (is (eq :candidate (g:stato-contesto-get small)))
               (is (e:epoca-attiva-p (active-read-epoch f 0)))
               (is (active-read-output-untouched-p (af-output f)))
               (is (null (active-reads f)))
               (signals invalid-argument (g:concludi-get small 12) :get-result-not-ready)
               (is (e:epoca-attiva-p (active-read-epoch f 0)))
               (g:abbandona-get small)
               (is (active-read-clean-p small (active-read-epoch f 0)))
               ;; Si conserva la richiesta: nuova pagina, poi nuovo lookup ed EBR sul worker1.
               (active-publish-through f 2)
               (active-read-reset f)
               (active-read-start f 0 1)
               (is (= 8 (aref (g::contesto-get-content large) 0)))
               (is (= 176 (ldb (byte 32 0) (aref (g::contesto-get-content large) 1))))
               (is (equal '(:segment :disabled :not-attempted nil nil)
                          (multiple-value-list (r:leggi-record-attivo-get large (af-source f)))))
               (is (equal '((176 56)) (active-read-offset-counts f)))
               (active-read-copy-and-finish large (active-read-epoch f 1) (af-output f) new-value)
               (is (active-read-clean-p small (active-read-epoch f 0))))
          (g:abbandona-get small)
          (g:abbandona-get large))))))

;;; REQ: REQ-MVC-004 REQ-CON-004 REQ-CMP-007
(deftest test-REQ-MVC-004-active-snapshot-expires-after-private-copy
  (let ((key (active-read-bytes 16 #x71)) (value (active-read-bytes 16 #x91)))
    (with-active-fixture
        (f :cache-p nil :base #x100000000 :batches (list (list (active-read-put key value))))
      (let ((context (af-context f)) (authorized nil))
        (unwind-protect
             (progn
               (active-register-snapshot f 10)
               (active-read-reset f)
               (is (eq :candidate (active-begin f 0 :now 11 :snapshot-p t)))
               (is (equal '(:segment :disabled :not-attempted nil nil)
                          (multiple-value-list (r:leggi-record-attivo-get context (af-source f)))))
               (is (= 19 (g:copia-valore-get context (af-output f) 3)))
               (is (eq :copied (g:stato-contesto-get context)))
               (is (e:epoca-attiva-p (active-read-epoch f)))
               (is (active-read-check-output (af-output f) value))
               (signals arcdocdb.conditions:snapshot-too-old
                 (progn (g:concludi-get context 30) (setf authorized t))
                 :snapshot-age-expired)
               (is (null authorized))
               (is (active-read-clean-p context (active-read-epoch f)))
               (is (active-read-check-output (af-output f) value))
               (signals invalid-argument (g:concludi-get context 12) :get-result-not-ready))
          (g:abbandona-get context))))))
