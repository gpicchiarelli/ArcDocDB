(in-package #:arcdocdb.get.directory.tests)

(defun directory-call-operation (operation context directory)
  (ecase operation
    (:select (d:trova-mappa-directory-get context directory))
    (:resolve (d:risolvi-candidato-directory-get context directory))
    (:probe (d:sonda-cache-directory-get context directory))
    (:read (d:leggi-record-directory-get context directory))))
(defun directory-output-untouched-p (fixture &optional (worker 0))
  (every (lambda (byte) (= byte +directory-sentinel+)) (aref (directory-fixture-outputs fixture) worker)))
(defun directory-copy-and-finish (fixture &optional (worker 0) (ordinal 0) (now 12))
  (let ((context (aref (directory-fixture-contexts fixture) worker)))
    (is (= (+ 3 (length (aref (directory-fixture-values fixture) ordinal)))
           (g:copia-valore-get context (aref (directory-fixture-outputs fixture) worker) 3)))
    (is (equal (list :found (length (aref (directory-fixture-values fixture) ordinal)))
               (multiple-value-list (g:concludi-get context now))))
    (is (directory-check-output fixture worker ordinal))
    (is (directory-check-clean fixture worker))))

;;; REQ: REQ-IDX-001 REQ-FOR-002 REQ-FOR-004 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-native-read-v1-v2-values-and-maxid
  (dolist (version '(1 2))
    (dolist (value-bytes '(16 256 4096))
      (with-directory-fixture (fixture :count 4 :version version :value-bytes value-bytes
                                      :cache-p nil :observe-io-p t)
        (dotimes (ordinal 4)
          (let ((context (aref (directory-fixture-contexts fixture) 0)))
            (unwind-protect
                 (progn
                   (is (eq :candidate (directory-begin fixture :ordinal ordinal)))
                   ;; Acquisizione della directory pubblicata soltanto entro il compito EBR.
                   (let* ((directory (directory-fixture-directory fixture))
                          (map (d:trova-mappa-directory-get context directory))
                          (resolved (multiple-value-list (d:risolvi-candidato-directory-get context directory)))
                          (candidate (directory-words 5 #xdeadbeef)))
                     (g:copia-candidato-get context candidate)
                     (is (= +directory-max-csn+ (aref candidate 0)))
                     (is (= (logior (ash (aref (directory-fixture-ids fixture) ordinal) 32) 64)
                            (aref candidate 1)))
                     (is (= (+ 40 value-bytes) (aref candidate 3)))
                     (is (eq map (aref (directory-fixture-maps fixture) ordinal)))
                     (is (equal (list (r::mappa-segmento-get-segment map)
                                      (aref (directory-fixture-ends fixture) ordinal) 0 nil) resolved))
                     (is (eq :candidate (g:stato-contesto-get context)))
                     (is (null (directory-read-events fixture)))
                     (is (equal '(:segment :disabled :not-attempted nil nil)
                                (multiple-value-list (d:leggi-record-directory-get context directory)))))
                   (directory-copy-and-finish fixture 0 ordinal)
                   (is (equal (list (list (aref (directory-fixture-ids fixture) ordinal) 64 (+ 40 value-bytes)))
                              (directory-read-events fixture))))
              (g:abbandona-get context)))
          (directory-clear-read-events fixture))))))

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-CCH-002-directory-cache-enums-and-private-output
  (dolist (version '(1 2))
    (with-directory-fixture (fixture :count 4 :version version :observe-io-p t)
      (let ((context (aref (directory-fixture-contexts fixture) 0)))
        (dotimes (ordinal 4)
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture :ordinal ordinal)))
                 (is (eq :miss (d:sonda-cache-directory-get context (directory-fixture-directory fixture))))
                 (is (eq :candidate (g:stato-contesto-get context)))
                 (is (null (directory-read-events fixture)))
                 (is (equal '(:segment :miss :inserted nil nil)
                            (multiple-value-list (d:leggi-record-directory-get context (directory-fixture-directory fixture)))))
                 (directory-copy-and-finish fixture 0 ordinal))
            (g:abbandona-get context))
          (directory-clear-read-events fixture))
        (dotimes (ordinal 4)
          (fill (aref (directory-fixture-outputs fixture) 0) +directory-sentinel+)
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture :ordinal ordinal)))
                 (is (eq :hit (d:sonda-cache-directory-get context (directory-fixture-directory fixture))))
                 (directory-copy-and-finish fixture 0 ordinal))
            (g:abbandona-get context))
          (is (equal '(:cache :hit :not-attempted nil nil)
                     (nth-value 2 (directory-checked-read fixture :ordinal ordinal))))
          (is (null (directory-read-events fixture))))))))

(defun directory-corrupt-cached-value (fixture)
  "FI seriale sull'entry cache propria, identificata dai quattro tag, senza lookup del prodotto."
  (let* ((class (aref (c::cache-serie-classes (directory-fixture-cache fixture)) 0))
         (tags (c::classe-cache-tags class)) (arena (c::classe-cache-arena class))
         (size (c::classe-cache-size class)) (id (aref (directory-fixture-ids fixture) 0))
         (record-bytes (+ 40 (length (aref (directory-fixture-values fixture) 0)))))
    (dotimes (slot (/ (length tags) 4))
      (let ((base (* 4 slot)))
        (when (and (= 0 (aref tags base)) (= id (aref tags (+ base 1)))
                   (= 64 (aref tags (+ base 2))) (= record-bytes (aref tags (+ base 3))))
          (let ((byte (+ (* slot size) 40)))
            (setf (aref arena byte) (logxor 1 (aref arena byte))))
          (return-from directory-corrupt-cached-value t))))
    (error 'directory-fixture-error :reason :cached-entry-not-found)))

;;; REQ: REQ-CCH-004 REQ-CCH-002 REQ-AFF-002 REQ-CMP-007
(deftest test-REQ-CCH-004-directory-cache-verify-failed-native-fallback
  (dolist (version '(1 2))
    (dolist (operation '(:probe :read))
      (with-directory-fixture (fixture :version version :observe-io-p t)
        (is (equal '(:segment :miss :inserted nil nil) (nth-value 2 (directory-checked-read fixture))))
        (fill (aref (directory-fixture-outputs fixture) 0) +directory-sentinel+)
        (directory-clear-read-events fixture)
        (directory-corrupt-cached-value fixture)
        (let ((context (aref (directory-fixture-contexts fixture) 0)))
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture)))
                 (when (eq operation :probe)
                   (is (eq :verify-failed
                           (d:sonda-cache-directory-get context (directory-fixture-directory fixture))))
                   (is (eq :candidate (g:stato-contesto-get context)))
                   (is (directory-output-untouched-p fixture))
                   (is (null (directory-read-events fixture))))
                 (is (equal (list :segment (if (eq operation :probe) :miss :verify-failed) :inserted nil nil)
                            (multiple-value-list (d:leggi-record-directory-get context (directory-fixture-directory fixture)))))
                 (directory-copy-and-finish fixture)
                 (is (equal '((4294967295 64 56)) (directory-read-events fixture))))
            (g:abbandona-get context)))))))

(defun directory-reference-mix-cache (word)
  "Oracolo del routing u32, senza chiamare le primitive della cache."
  (let* ((a (logxor word (floor word 65536)))
         (b (mod (* a #x7feb352d) #x100000000))
         (c (logxor b (floor b 32768)))
         (d (mod (* c #x846ca68b) #x100000000)))
    (logxor d (floor d 65536))))
(defun directory-reference-cache-set (id)
  (mod (directory-reference-mix-cache
        (logxor (directory-reference-mix-cache 0)
                (directory-reference-mix-cache (logxor id #x9e3779b9))
                (directory-reference-mix-cache (logxor 64 #x85ebca6b)))) 256))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-001-directory-cache64-no-eviction-and-every-hit
  (dolist (value-bytes '(16 4096))
    (with-directory-fixture (fixture :count 64 :value-bytes value-bytes :observe-io-p t)
      (let ((occupancy (make-array 256 :initial-element 0))
            (class (aref (c::cache-serie-classes (directory-fixture-cache fixture)) 0)))
        (is (= 256 (c::classe-cache-sets class)))
        (is (>= (c::classe-cache-size class) 1024))
        (dotimes (ordinal 64)
          (let* ((id (aref (directory-fixture-ids fixture) ordinal))
                 (set (directory-reference-cache-set id)))
            (is (= set (c::insieme-cache class 0 id 64)))
            (incf (aref occupancy set))))
        (is (every (lambda (count) (<= count 8)) occupancy))
        (dotimes (ordinal 64)
          (is (equal '(:segment :miss :inserted nil nil)
                     (nth-value 2 (directory-checked-read fixture :ordinal ordinal)))))
        (directory-clear-read-events fixture)
        ;; Warm TUTTE le chiavi, poi ciascun accesso deve essere HIT senza pread.
        (dotimes (pass 2)
          (dotimes (ordinal 64)
            (is (equal '(:cache :hit :not-attempted nil nil)
                       (nth-value 2 (directory-checked-read fixture :ordinal ordinal))))))
        (is (null (directory-read-events fixture)))))))

;;; REQ: REQ-FOR-003 REQ-FOR-004 REQ-CCH-002 REQ-CMP-007
(deftest test-REQ-FOR-004-directory-prepared-writer-outcome-seal
  (dolist (version '(1 2))
    (with-directory-fixture (fixture :count 3 :version version :prepared-p t :observe-io-p t)
      (dotimes (ordinal 3)
        (let ((context (aref (directory-fixture-contexts fixture) 0)))
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture :ordinal ordinal)))
                 (multiple-value-bind (segment end flags proof)
                     (d:risolvi-candidato-directory-get context (directory-fixture-directory fixture))
                   (is (eq segment (r::mappa-segmento-get-segment (aref (directory-fixture-maps fixture) ordinal))))
                   (is (= end (aref (directory-fixture-ends fixture) ordinal)))
                   (is (= 1 flags))
                   (is (= 120 proof))) ; 64 + 24 + key16 + value16
                 (is (eq :proof-required (d:sonda-cache-directory-get context (directory-fixture-directory fixture))))
                 (is (null (directory-read-events fixture)))
                 (is (equal '(:segment :miss :inserted nil nil)
                            (multiple-value-list (d:leggi-record-directory-get context (directory-fixture-directory fixture)))))
                 (directory-copy-and-finish fixture 0 ordinal)
                 (is (equal (list (list (aref (directory-fixture-ids fixture) ordinal) 120 32)
                                       (list (aref (directory-fixture-ids fixture) ordinal) 64 56))
                            (directory-read-events fixture))))
            (g:abbandona-get context)))
        (directory-clear-read-events fixture)
        (is (equal '(:cache :hit :not-attempted nil nil)
                   (nth-value 2 (directory-checked-read fixture :ordinal ordinal))))
        ;; Prepared legge sempre OUTCOME, anche con cache calda: nessun HIT senza prova.
        (is (equal (list (list (aref (directory-fixture-ids fixture) ordinal) 120 32))
                   (directory-read-events fixture)))
        (directory-clear-read-events fixture)))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-missing-published-candidate-failstop
  (dolist (operation '(:select :resolve :probe :read))
    (dolist (mode '(:empty :gap))
      (with-directory-fixture (fixture :count 3 :observe-io-p t)
        (let ((context (aref (directory-fixture-contexts fixture) 0)) (authorized nil))
          (when (eq mode :gap)
            (directory-publish-key fixture (directory-fixture-missing-key fixture) +directory-max-csn+ 18 64 56))
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture :missing-p (eq mode :gap))))
                 (let ((directory (if (eq mode :empty)
                                      (d:crea-directory-get-serie (directory-fixture-view fixture) #())
                                      (directory-fixture-directory fixture))))
                   (signals invariant-violation
                     (progn (directory-call-operation operation context directory) (setf authorized t))
                     :directory-location-absent))
                 (is (null authorized))
                 (is (directory-check-clean fixture 0 :faulted))
                 (is (directory-output-untouched-p fixture))
                 (is (null (directory-read-events fixture)))
                 ;; FAULTED resta terminale dopo il cleanup; nessun risultato ABSENT/FOUND disponibile.
                 (signals invalid-argument (g:concludi-get context 12) :get-result-not-ready)
                 (signals invalid-argument (directory-begin fixture) :get-worker-state))
            (g:abbandona-get context)))))))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CMP-007-directory-wrong-owner-cleanup-all-entrypoints
  (dolist (operation '(:select :resolve :probe :read))
    (with-directory-fixture (fixture :observe-io-p t)
      (with-directory-fixture (foreign :observe-io-p t)
        (let ((context (aref (directory-fixture-contexts fixture) 0)))
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture)))
                 (signals invalid-argument
                   (directory-call-operation operation context (directory-fixture-directory foreign))
                   :directory-source-owner)
                 (is (directory-check-clean fixture))
                 (is (directory-output-untouched-p fixture))
                 (is (null (directory-read-events fixture)))
                 (is (null (directory-read-events foreign)))
                 (is (eq :found (directory-checked-read fixture))))
            (g:abbandona-get context)))))))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-AFF-004
(deftest test-REQ-IDX-001-directory-candidate-csn-low-and-high
  (dolist (version '(1 2))
    (dolist (bit '(0 63))
      (with-directory-fixture (fixture :version version :record-csn (logxor +directory-max-csn+ (ash 1 bit))
                                      :observe-io-p t)
        (let ((context (aref (directory-fixture-contexts fixture) 0)))
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture)))
                 (signals invariant-violation
                   (d:leggi-record-directory-get context (directory-fixture-directory fixture))
                   :resolver-candidate-csn)
                 (is (directory-check-clean fixture 0 :faulted))
                 (is (directory-output-untouched-p fixture))
                 (is (null (directory-read-events fixture))))
            (g:abbandona-get context)))))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-FOR-004
(deftest test-REQ-IDX-001-directory-candidate-size-and-highbits
  (dolist (variant '(:short :long :reserved-high))
    (with-directory-fixture (fixture :observe-io-p t)
      (let ((context (aref (directory-fixture-contexts fixture) 0)))
        (when (member variant '(:short :long))
          (directory-publish-key fixture (directory-fixture-missing-key fixture) +directory-max-csn+ #xffffffff 64
                                 (if (eq variant :short) 55 57)))
        (unwind-protect
             (progn
               (is (eq :candidate (directory-begin fixture :missing-p (not (eq variant :reserved-high)))))
               ;; Le word riservate non sono pubblicabili dal primary: FI solo sullo scratch proprietario.
               (when (eq variant :reserved-high)
                 (setf (aref (g::contesto-get-content context) 3) #x100000038))
               (signals invariant-violation
                 (d:risolvi-candidato-directory-get context (directory-fixture-directory fixture))
                 :resolver-candidate-size)
               (is (directory-check-clean fixture 0 :faulted))
               (is (directory-output-untouched-p fixture))
               (is (null (directory-read-events fixture))))
          (g:abbandona-get context))))))

;;; REQ: REQ-FOR-004 REQ-IDX-001 REQ-AFF-002 REQ-CMP-007
(deftest test-REQ-FOR-004-directory-source-key-mismatch-no-authorized-value
  (with-directory-fixture (fixture :cache-p nil :observe-io-p t)
    ;; CSN, segmento, offset e size corretti; solo la chiave richiesta è differente.
    (directory-publish-key fixture (directory-fixture-missing-key fixture) +directory-max-csn+ #xffffffff 64 56)
    (let ((context (aref (directory-fixture-contexts fixture) 0)) (authorized nil))
      (unwind-protect
           (progn
             (is (eq :candidate (directory-begin fixture :missing-p t)))
             (signals corruption-detected
               (progn (d:leggi-record-directory-get context (directory-fixture-directory fixture))
                      (setf authorized t)) :index-mismatch)
             (is (null authorized))
             (is (directory-output-untouched-p fixture))
             (is (directory-check-clean fixture))
             (is (equal '((4294967295 64 56)) (directory-read-events fixture))))
        (g:abbandona-get context)))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-shape-FI-before-source-read
  (dolist (operation '(:select :resolve :probe :read))
    (dolist (variant '(:different-lengths :over-maximum))
      (with-directory-fixture (fixture :observe-io-p t)
        (let ((context (aref (directory-fixture-contexts fixture) 0)))
          (unwind-protect
               (progn
                 (is (eq :candidate (directory-begin fixture)))
                 (let* ((real (directory-fixture-directory fixture))
                        (bad (d::%make-directory-get-serie
                              (directory-fixture-view fixture)
                              (if (eq variant :different-lengths) (d::directory-get-serie-ids real)
                                  (make-array 65537 :element-type '(unsigned-byte 32) :initial-element 1))
                              (if (eq variant :different-lengths) #()
                                  (make-array 65537 :initial-element (aref (directory-fixture-maps fixture) 0))))))
                   (signals invariant-violation (directory-call-operation operation context bad) :directory-shape))
                 (is (directory-check-clean fixture 0 :faulted))
                 (is (directory-output-untouched-p fixture))
                 (is (null (directory-read-events fixture))))
            (g:abbandona-get context)))))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-private-NIL-entry-shape-FI-all-entrypoints
  (dolist (operation '(:select :resolve :probe :read))
    (with-directory-fixture (fixture :observe-io-p t)
      (let ((context (aref (directory-fixture-contexts fixture) 0)) (authorized nil))
        (unwind-protect
             (progn
               (is (eq :candidate (directory-begin fixture)))
               (let* ((directory (directory-fixture-directory fixture))
                      (ids (d::directory-get-serie-ids directory))
                      (maps (d::directory-get-serie-maps directory)))
                 (is (= 1 (length ids) (length maps)))
                 (is (= #xffffffff (aref ids 0)))
                 ;; FI sull'array privato della sola fixture, lunghezze e ID ancora validi.
                 (setf (svref maps 0) nil)
                 (signals invariant-violation
                   (progn (directory-call-operation operation context directory) (setf authorized t))
                   :directory-shape))
               (is (null authorized))
               (is (directory-check-clean fixture 0 :faulted))
               (is (directory-output-untouched-p fixture))
               (is (null (directory-read-events fixture)))
               (g:abbandona-get context)
               (is (directory-check-clean fixture 0 :faulted)))
          (g:abbandona-get context))))))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-IDX-001-directory-closed-FD-after-publication
  (dolist (operation '(:resolve :probe :read))
    (with-directory-fixture (fixture :observe-io-p t)
      (let ((context (aref (directory-fixture-contexts fixture) 0)))
        ;; FI del controller a quiescenza; esercita il controllo della durata del FD.
        (io:chiudi (aref (directory-fixture-files fixture) 0))
        (unwind-protect
             (progn
               (is (eq :candidate (directory-begin fixture)))
               (signals invariant-violation
                 (directory-call-operation operation context (directory-fixture-directory fixture))
                 :resolver-source-lifetime)
               (is (directory-check-clean fixture 0 :faulted))
               (is (null (directory-read-events fixture))))
          (g:abbandona-get context))))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CON-004-directory-state-before-cleanup-and-reentrancy
  (dolist (operation '(:select :resolve :probe :read))
    (with-directory-fixture (fixture :cache-p nil :observe-io-p t)
      (let ((context (aref (directory-fixture-contexts fixture) 0)))
        (signals invalid-argument
          (directory-call-operation operation context (directory-fixture-directory fixture)) :get-worker-state)
        (is (directory-check-clean fixture))
        (unwind-protect
             (progn
               (is (eq :candidate (directory-begin fixture)))
               (let ((candidate (directory-words 5)) (after (directory-words 5)))
                 (g:copia-candidato-get context candidate)
                 (signals invalid-argument (directory-begin fixture) :get-worker-state)
                 (g:copia-candidato-get context after)
                 (is (equalp candidate after)))
               (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs fixture) 0)))
               (d:leggi-record-directory-get context (directory-fixture-directory fixture))
               ;; Chiamata fuori ordine in VERIFIED: deve conservare il compito già in corso.
               (signals invalid-argument
                 (directory-call-operation operation context (directory-fixture-directory fixture)) :get-worker-state)
               (is (eq :verified (g:stato-contesto-get context)))
               (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs fixture) 0)))
               (directory-copy-and-finish fixture))
          (g:abbandona-get context))))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CON-004-directory-throw-during-native-read-cleans-pin
  (with-directory-fixture (fixture :cache-p nil :observe-io-p t)
    (let ((context (aref (directory-fixture-contexts fixture) 0))
          (observer (directory-fixture-observer fixture)))
      (setf (directory-observer-hook observer)
            (lambda (id offset count)
              (declare (ignore id offset count)) (throw 'directory-read-escape :escaped)))
      (unwind-protect
           (progn
             (is (eq :candidate (directory-begin fixture)))
             ;; Nessun cleanup esterno prima dell'osservazione: esercita quello del prodotto.
             (is (eq :escaped
                     (catch 'directory-read-escape
                       (d:leggi-record-directory-get context (directory-fixture-directory fixture)) :unexpected)))
             (is (directory-check-clean fixture))
             (is (directory-output-untouched-p fixture))
             (setf (directory-observer-hook observer) nil)
             (is (eq :found (directory-checked-read fixture))))
        (setf (directory-observer-hook observer) nil)
        (g:abbandona-get context)))))

;;; REQ: REQ-MVC-004 REQ-MVC-005 REQ-CMP-007
(deftest test-REQ-MVC-004-directory-fresh-snapshot-final-authorization
  (with-directory-fixture (fixture :observe-io-p t)
    (directory-register-snapshot fixture)
    (is (eq :found (directory-checked-read fixture :finish-now 12)))
    (let ((authorized nil))
      (signals snapshot-too-old
        (progn (directory-checked-read fixture :finish-now 30) (setf authorized t)) :snapshot-age-expired)
      (is (null authorized))
      (is (directory-check-output fixture 0 0))
      (is (directory-check-clean fixture)))))

;;; REQ: REQ-IDX-001 REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-primary-absence-and-snapshot-history
  (dolist (snapshot-p '(nil t))
    (with-directory-fixture (fixture :count 0 :observe-io-p t)
      (when snapshot-p (directory-register-snapshot fixture))
      (let ((context (aref (directory-fixture-contexts fixture) 0))
            (expected (if snapshot-p :history-required :absent)))
        (unwind-protect
             (progn
               (is (eq expected (directory-begin fixture :missing-p t)))
               (signals invalid-argument
                 (d:trova-mappa-directory-get context (directory-fixture-directory fixture)) :get-worker-state)
               (is (eq expected (g:stato-contesto-get context)))
               (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs fixture) 0)))
               (is (equal (list expected 0) (multiple-value-list (g:concludi-get context 12))))
               (is (directory-output-untouched-p fixture))
               (is (null (directory-read-events fixture)))
               (is (directory-check-clean fixture)))
          (g:abbandona-get context))))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-IDX-001
(deftest test-REQ-CON-004-directory-buffer-required-restarts-in-new-worker
  (with-directory-fixture (fixture :value-bytes 4096 :record-bytes 56 :observe-io-p t)
    (let ((small (aref (directory-fixture-contexts fixture) 0)))
      (unwind-protect
           (progn
             (is (eq :candidate (directory-begin fixture)))
             (is (eq :buffer-required (d:sonda-cache-directory-get small (directory-fixture-directory fixture))))
             (is (equal '(:buffer-required :not-attempted :not-attempted nil nil)
                        (multiple-value-list (d:leggi-record-directory-get small (directory-fixture-directory fixture)))))
             (is (null (directory-read-events fixture))))
        (g:abbandona-get small))
      (is (directory-check-clean fixture))
      ;; Trasferisce soltanto la richiesta; un altro worker riesegue AVVIA e risolve di nuovo.
      (setf (aref (directory-fixture-contexts fixture) 1)
            (g:crea-contesto-get (directory-fixture-scope fixture) 1 :record-bytes 4136 :budget-payload 4288))
      (is (eq :found (directory-checked-read fixture :worker 1)))
      (is (directory-check-clean fixture 1)))))
