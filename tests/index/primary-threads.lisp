;;;; Worker reali SWMR; nessuna FI globale mentre i worker sono attivi.
;;; OWNER: unico worker writer dopo l'avvio; ciascun reader possiede context/output/statistiche.
;;; SHARED: indice e chiavi immutabili; semafori del solo harness delimitano le fasi.
(in-package #:arcdocdb.index.primary.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-IDX-003 REQ-CON-004
(declaim (ftype (function (&optional integer) integer) primary-deadline))
(defun primary-deadline (&optional (seconds 30))
  "Pre: durata positiva del test. Post: limite unico condiviso dalle attese del suo harness."
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

;;; REQ: REQ-IDX-003 REQ-CON-004
(declaim (ftype (function (integer) double-float) primary-seconds-left))
(defun primary-seconds-left (deadline)
  "Pre: deadline del test. Post: secondi residui positivi; errore tipizzato all'esaurimento."
  (let ((remaining (- deadline (get-internal-real-time))))
    (unless (plusp remaining) (error 'resource-exhausted :reason :primary-test-timeout))
    (/ remaining (float internal-time-units-per-second 1d0))))

;;; REQ: REQ-CON-004
(declaim (ftype (function (sb-thread:semaphore integer) boolean) primary-wait))
(defun primary-wait (semaphore deadline)
  "Pre: semaforo dell'harness. Post: attesa conclusa entro il limite oppure test fallito."
  (is (sb-thread:wait-on-semaphore semaphore :timeout (primary-seconds-left deadline)))
  t)

;;; REQ: REQ-IDX-003 REQ-CON-004
(declaim (ftype (function (string function) sb-thread:thread) primary-worker))
(defun primary-worker (name thunk)
  "Confine worker: un errore e il risultato registrato del thread, rilanciato dal runner al join."
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))

;;; REQ: REQ-IDX-003 REQ-CON-004
(declaim (ftype (function (sb-thread:thread integer) list) primary-join))
(defun primary-join (thread deadline)
  "Pre: worker creato dalla fixture. Post: risultato :OK controllato; errore del worker propagato."
  (let ((result (sb-thread:join-thread thread :timeout (primary-seconds-left deadline)
                                            :default :primary-timeout)))
    (when (typep result 'error) (error result))
    (is (consp result))
    (is (eq :ok (first result)))
    (the list result)))

;;; REQ: REQ-CON-004
(declaim (ftype (function (list) null) primary-stop-workers))
(defun primary-stop-workers (threads)
  "Cleanup: solo worker della fixture, join di un secondo ciascuno; errori conservati e rilanciati."
  (let ((failure nil))
    (dolist (thread threads)
      (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
      (let ((result (sb-thread:join-thread thread :timeout 1 :default :primary-stopped)))
        (when (typep result 'error) (unless failure (setf failure result)))
        (is (not (sb-thread:thread-alive-p thread)))))
    (when failure (error failure)))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003
(declaim (ftype (function (octets u64) s::contenuto-slot) primary-thread-payload))
(defun primary-thread-payload (key csn)
  "Pre: CSN di fixture <=1001. Post: location e lunghezza derivate indipendentemente dalla versione."
  (primary-payload key csn :location (+ (ash csn 32) (* csn 128)) :extra (1+ (mod csn 64))))

;;; REQ: REQ-IDX-003
(declaim (ftype (function (p:indice-primario octets p:contesto-indice s::contenuto-slot u64 u64)
                         (values u64 boolean &optional)) primary-observe-update))
(defun primary-observe-update (index key context output previous maximum)
  "Pre: scratch/output privati. Post: LIVE interamente coerente/monotono, RETRY senza scrittura."
  (fill output +primary-sentinel+)
  (case (p:leggi-indice-primario index key 0 (length key) 0 3 context output)
    (:live
     (let ((csn (aref output 0)))
       (is (<= 1 csn maximum))
       (is (<= previous csn))
       (is (= (aref output 1) (+ (ash csn 32) (* csn 128))))
       (is (= (aref output 2) (logior (ash (length key) 32) (ash 1 48))))
       (is (= (aref output 3) (+ arcdocdb.record:+header-bytes+ (length key) 1 (mod csn 64))))
       (is (zerop (aref output 4)))
       (values csn t)))
    (:retry-limit
     (is (every (lambda (word) (= word +primary-sentinel+)) output))
     (values previous nil))
    (otherwise (error 'invariant-violation :reason :primary-test-unexpected-update-state))))

;;; REQ: REQ-IDX-003 REQ-CON-004
(declaim (ftype (function (p:indice-primario octets sb-thread:semaphore sb-thread:semaphore
                         sb-thread:semaphore integer integer u64) list) primary-update-reader))
(defun primary-update-reader (index key ready start finished deadline iterations maximum)
  "Pre: worker reader esclusivo. Post: campioni concorrenti controllati e versione finale osservata."
  (let ((context (p:crea-contesto-indice))
        (output (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
        (previous 0) (hits 0) (retries 0))
    (multiple-value-bind (csn live) (primary-observe-update index key context output 0 maximum)
      (is live)
      (setf previous csn)
      (incf hits))
    (sb-thread:signal-semaphore ready)
    (primary-wait start deadline)
    (dotimes (iteration iterations)
      (primary-seconds-left deadline)
      (multiple-value-bind (csn live)
          (primary-observe-update index key context output previous maximum)
        (setf previous csn)
        (if live (incf hits) (incf retries)))
      (when (zerop (mod iteration 16)) (sb-thread:thread-yield)))
    (primary-wait finished deadline)
    (multiple-value-bind (csn live)
        (primary-observe-update index key context output previous maximum)
      (is live)
      (is (= maximum csn)))
    (is (not (p::contesto-indice-busy context)))
    (is (= (1+ iterations) (+ hits retries)))
    (list :ok hits retries)))

;;; REQ: REQ-IDX-003 REQ-CON-004
(declaim (ftype (function (primary-fixture octets sb-thread:semaphore sb-thread:semaphore
                         integer integer integer) list) primary-update-writer))
(defun primary-update-writer (fixture key start finished deadline iterations readers)
  "Pre: gettone writer trasferito a questo worker. Post: tutte le versioni pubblicate in ordine."
  (primary-wait start deadline)
  (dotimes (iteration iterations)
    (primary-seconds-left deadline)
    (let* ((csn (+ iteration 2)) (payload (primary-thread-payload key csn)))
      (primary-put fixture key csn 0 3 :source payload))
    (when (zerop (mod iteration 8)) (sb-thread:thread-yield)))
  (sb-thread:signal-semaphore finished readers)
  (list :ok iterations))

;;; REQ: REQ-IDX-003 REQ-IDX-001 REQ-CON-004
(deftest test-REQ-IDX-003-primary-writer-updates-three-readers-no-torn-payload
  "Pre: una chiave viva. Post: 1000 update e 12000 lookup concorrenti con controllo di tutte le parole."
  (let* ((f (primary-fixture)) (index (primary-fixture-index f)) (key (primary-key 1 0))
         (readers 3) (updates 1000) (iterations 4000) (deadline (primary-deadline))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (finished (sb-thread:make-semaphore)) (threads nil))
    (primary-put f key 1 0 3 :source (primary-thread-payload key 1))
    (unwind-protect
         (progn
           (push (primary-worker "primary writer updates"
                                 (lambda () (primary-update-writer
                                             f key start finished deadline updates readers))) threads)
           (dotimes (reader readers)
             (push (primary-worker (format nil "primary update reader ~D" reader)
                                   (lambda () (primary-update-reader
                                               index key ready start finished deadline
                                               iterations (1+ updates)))) threads))
           (dotimes (reader readers) (primary-wait ready deadline))
           (sb-thread:signal-semaphore start (1+ readers))
           (dolist (thread threads) (primary-join thread deadline))
           (primary-live f key 0 3 (primary-thread-payload key (1+ updates)) 0))
      (primary-stop-workers threads))))

;;; REQ: REQ-IDX-003 REQ-IDX-007
(declaim (ftype (function (p:indice-primario octets octets p:contesto-indice
                         s::contenuto-slot s::contenuto-slot) boolean) primary-observe-root))
(defun primary-observe-root (index key missing context output expected)
  "Pre: reader privato. Post: hit coerente o retry; miss/retry preservano tutte le cinque parole."
  (fill output +primary-sentinel+)
  (case (p:leggi-indice-primario index key 0 (length key) 0 1 context output)
    (:live
     (primary-check-payload output expected)
     (is (<= (ldb (byte 32 0) (aref output 2)) 4)))
    (:retry-limit (is (every (lambda (word) (= word +primary-sentinel+)) output)))
    (otherwise (error 'invariant-violation :reason :primary-test-unexpected-root-hit)))
  (fill output +primary-sentinel+)
  (is (member (p:leggi-indice-primario index missing 0 (length missing) 0 1 context output)
              '(:absent :retry-limit)))
  (is (every (lambda (word) (= word +primary-sentinel+)) output))
  (is (not (p::contesto-indice-busy context)))
  t)

;;; REQ: REQ-IDX-003 REQ-IDX-007 REQ-CON-004
(declaim (ftype (function (p:indice-primario octets octets s::contenuto-slot sb-thread:semaphore
                         sb-thread:semaphore sb-thread:semaphore integer integer) list)
                primary-root-reader))
(defun primary-root-reader (index key missing expected ready start finished deadline iterations)
  "Pre: worker reader esclusivo. Post: letture limitate durante crescita arena e cambi root."
  (let ((context (p:crea-contesto-indice))
        (output (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))
    (primary-observe-root index key missing context output expected)
    (sb-thread:signal-semaphore ready)
    (primary-wait start deadline)
    (dotimes (iteration iterations)
      (primary-seconds-left deadline)
      (primary-observe-root index key missing context output expected)
      (when (zerop (mod iteration 16)) (sb-thread:thread-yield)))
    (primary-wait finished deadline)
    (primary-observe-root index key missing context output expected)
    (is (eq :live (p:leggi-indice-primario index key 0 (length key) 0 1 context output)))
    (primary-check-payload output expected)
    (list :ok iterations)))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-CON-004
(declaim (ftype (function (primary-fixture octets octets sb-thread:semaphore sb-thread:semaphore
                         integer integer integer) list) primary-rebuild-writer))
(defun primary-rebuild-writer (fixture a b start finished deadline waves readers)
  "Pre: writer esclusivo. Post: crescita e copie manuali vive, sorgenti congelati a ogni pubblicazione."
  (primary-wait start deadline)
  (dotimes (wave waves)
    (primary-seconds-left deadline)
    (let* ((source (primary-current fixture)) (new-size (+ 512 wave))
           (candidate (primary-candidate fixture 0 0 4)))
      (is (null (p:estendi-arena-indice (primary-fixture-index fixture) source new-size
                                      (+ (primary-root-bytes fixture) new-size))))
      (if (evenp wave)
          (progn (primary-copy-live fixture candidate b 0 2)
                 (primary-copy-live fixture candidate a 0 1))
          (progn (primary-copy-live fixture candidate a 0 1)
                 (primary-copy-live fixture candidate b 0 2)))
      (is (null (p:pubblica-directory-indice (primary-plan fixture source candidate))))
      (is (eq :frozen (s::banco-slot-state (p::frammento-indice-bank source)))))
    (sb-thread:thread-yield))
  (sb-thread:signal-semaphore finished readers)
  (list :ok waves))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-IDX-003 REQ-CON-004
(deftest test-REQ-IDX-007-primary-manual-rebuilds-and-arena-growth-with-readers
  "Pre: due chiavi vive e byte morti. Post: 40 pubblicazioni con reader hit/miss privati."
  (let* ((f (primary-fixture)) (index (primary-fixture-index f))
         (dead (primary-key 0 0)) (a (primary-key 1 0)) (b (primary-key 2 0))
         (missing (primary-key 99 0)) (expected (primary-thread-payload a 7))
         (readers 3) (waves 40) (iterations 1500) (deadline (primary-deadline))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (finished (sb-thread:make-semaphore)) (threads nil))
    (primary-put f dead 1 0 0)
    (primary-put f a 7 0 1 :source expected)
    (primary-put f b 8 0 2 :source (primary-thread-payload b 8))
    (is (primary-delete f dead 0 0))
    (unwind-protect
         (progn
           (push (primary-worker "primary writer rebuilds"
                                 (lambda () (primary-rebuild-writer
                                             f a b start finished deadline waves readers))) threads)
           (dotimes (reader readers)
             (push (primary-worker (format nil "primary root reader ~D" reader)
                                   (lambda () (primary-root-reader
                                               index a missing expected ready start finished
                                               deadline iterations))) threads))
           (dotimes (reader readers) (primary-wait ready deadline))
           (sb-thread:signal-semaphore start (1+ readers))
           (dolist (thread threads) (primary-join thread deadline))
           (is (= waves (p::root-indice-generation (p::indice-primario-root index))))
           (is (= 4 (p::frammento-indice-used (primary-current f))))
           (primary-live f a 0 1 expected)
           (primary-no-output f dead 0 0 :absent))
      (primary-stop-workers threads))))
