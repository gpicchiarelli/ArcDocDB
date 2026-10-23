;;;; Harness C4: pubblicazioni reali, output privati e collisioni nello stesso insieme.
;;; OWNER: ogni worker possiede buffer e conteggi; il runner legge i risultati solo dopo join.
;;; SHARED: cache della singola Serie, record immutabili e soli semafori del test.
(in-package #:arcdocdb.cache.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-deadline (&optional (seconds 30))
  "Limite comune alle fasi della fixture; non misura prestazioni della cache."
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-seconds-left (deadline)
  "Secondi residui positivi; nessuna attesa della fixture può superare il limite."
  (let ((remaining (- deadline (get-internal-real-time))))
    (unless (plusp remaining) (error "Cache thread: deadline esaurita."))
    (/ remaining (float internal-time-units-per-second 1d0))))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-wait (semaphore deadline)
  "Attesa limitata del solo harness, senza sleep o polling."
  (unless (sb-thread:wait-on-semaphore semaphore :timeout (cache-thread-seconds-left deadline))
    (error "Cache thread: rendezvous scaduto."))
  t)

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-launch (name thunk notices)
  "Confine worker: SERIOUS-CONDITION diventa dato e viene rilanciata al join.
NOTICES sblocca sempre le sue fasi, anche se il worker fallisce prima del rendezvous."
  (sb-thread:make-thread
   (lambda ()
     (unwind-protect
          (handler-case (funcall thunk) (serious-condition (condition) condition))
       (dolist (notice notices) (sb-thread:signal-semaphore notice))))
   :name name))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-join (thread deadline)
  "Rilancia lo stesso oggetto condizione del worker; timeout e forma inattesa falliscono."
  (let ((result (sb-thread:join-thread thread :timeout (cache-thread-seconds-left deadline)
                                            :default :cache-thread-timeout)))
    (when (typep result 'serious-condition) (error result))
    (unless (and (consp result) (eq :ok (first result)))
      (error "Cache thread: esito inatteso al join: ~S." result))
    result))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-cleanup (threads gates)
  "Rilascia tutti i gate e termina/unisce tutti i worker ancora vivi, anche dopo errori.
Un errore del cleanup prevale sull'errore originale; i risultati dei worker non sono cleanup."
  (let ((failures nil))
    (dolist (gate gates)
      (handler-case (sb-thread:signal-semaphore gate 8)
        (serious-condition (condition) (push condition failures))))
    (dolist (thread threads)
      (handler-case
          (progn
            (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
            (sb-thread:join-thread thread :timeout 1 :default :cache-thread-cleanup-timeout)
            (when (sb-thread:thread-alive-p thread)
              (error "Cache thread: worker ancora vivo dopo cleanup.")))
        (serious-condition (condition) (push condition failures))))
    (when failures (error "Cache thread: errori cleanup: ~S." (nreverse failures))))
  nil)

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(defun cache-thread-count-insert (cache entry counts scan-p)
  "Un solo tentativo; eventi associati soltanto a INSERTED, senza retry dell'harness."
  (multiple-value-bind (status evicted polluted) (cache-insert cache entry :scan-p scan-p)
    (incf (aref counts 0))
    (case status
      (:inserted (incf (aref counts 1)))
      (:present (incf (aref counts 2)))
      (:busy (incf (aref counts 3)))
      (:unavailable (incf (aref counts 4)))
      (otherwise (error "Cache thread: inserimento inatteso: ~S." status)))
    (unless (eq status :inserted) (is (not evicted)) (is (not polluted)))
    (when evicted (incf (aref counts 7)))
    (when polluted (is evicted) (incf (aref counts 8))))
  nil)

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-AFF-002
(defun cache-thread-count-read (cache entry buffer counts)
  "Ogni hit è verificato integralmente dal helper; miss conserva solo range zero e guardie."
  (incf (aref counts 9))
  (case (cache-check-read cache entry buffer)
    (:hit (incf (aref counts 5)))
    (:miss (incf (aref counts 6)))
    (otherwise (error "Cache thread: lookup inatteso.")))
  nil)

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(defun cache-thread-step (cache entries buffer counts worker iteration)
  "32 record immutabili competono per otto vie; ogni passo inserisce e legge due identità."
  (let* ((position (mod (+ (* worker 7) (* iteration 5)) 32))
         (entry (svref entries position))
         (other (svref entries (mod (+ position 11 worker) 32))))
    (cache-thread-count-insert cache entry counts (oddp (+ worker iteration)))
    (cache-thread-count-read cache entry buffer counts)
    (cache-thread-count-read cache other buffer counts))
  nil)

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-stress-worker (cache entries buffer worker rounds deadline ready start sampled continue)
  "Buffer e conteggi restano esclusivi fino al join; un campione precede il secondo rendezvous.
La fase restante è libera: il test non attesta una specifica finestra del seqlock."
  (let ((counts (make-array 10 :initial-element 0)) (control (make-array 10 :initial-element 0)))
    ;; Gli altri worker non toccano la cache prima di START: questo campione
    ;; positivo è eseguito da un worker reale, prima della fase libera a quattro.
    (when (zerop worker)
      (cache-thread-count-insert cache (svref entries 8) control nil)
      (cache-thread-count-read cache (svref entries 8) buffer control))
    (sb-thread:signal-semaphore ready)
    (cache-thread-wait start deadline)
    (cache-thread-step cache entries buffer counts worker 0)
    (sb-thread:signal-semaphore sampled)
    (cache-thread-wait continue deadline)
    (loop for iteration from 1 below rounds
          do (cache-thread-seconds-left deadline)
             (cache-thread-step cache entries buffer counts worker iteration)
             (when (zerop (mod iteration 16)) (sb-thread:thread-yield)))
    (list :ok counts buffer control)))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(defun cache-thread-fill-set (cache entries)
  "Prepara otto vie occupate; il controllo hit/espulsione è poi eseguito dal worker zero."
  (dotimes (position 8)
    (multiple-value-bind (status evicted polluted) (cache-insert cache (svref entries position))
      (is (eq :inserted status)) (is (not evicted)) (is (not polluted))))
  nil)

;;; REQ: REQ-CCH-002 REQ-CCH-004
(defun cache-thread-check-buffers (buffers entries)
  "Dopo tutti i join: quattro destinazioni disgiunte fra loro e da tutti i dati immutabili."
  (dotimes (i (length buffers))
    (dotimes (j i) (is (not (eq (svref buffers i) (svref buffers j)))))
    (dotimes (j (length entries))
      (let ((entry (svref entries j)) (buffer (svref buffers i)))
        (is (not (eq buffer (cache-entry-record entry))))
        (is (not (eq buffer (cache-entry-key entry))))
        (is (not (eq buffer (cache-entry-value entry)))))))
  t)

;;; REQ: REQ-CCH-002 REQ-CCH-004
(defun cache-thread-input-image (entries)
  "Prima dell'avvio conserva tutti i record, le chiavi e i valori attesi immutabili."
  (map 'vector
       (lambda (entry)
         (list (copy-seq (cache-entry-record entry)) (copy-seq (cache-entry-key entry))
               (copy-seq (cache-entry-value entry))))
       entries))

;;; REQ: REQ-CCH-002 REQ-CCH-004
(defun cache-thread-check-input-image (entries before)
  "Dopo tutti i join: verifica ogni byte delle tre sorgenti condivise di ciascun record."
  (is (= (length entries) (length before)))
  (dotimes (i (length entries))
    (let ((entry (svref entries i)) (image (svref before i)))
      (is (equalp (cache-entry-record entry) (first image)))
      (is (equalp (cache-entry-key entry) (second image)))
      (is (equalp (cache-entry-value entry) (third image)))))
  t)

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(defun cache-thread-report-stress (results version value-bytes rounds)
  "Solo dopo tutti i join: riduzione dei contatori privati e non-vacuità della fase libera."
  (let ((total (make-array 10 :initial-element 0)) (control (make-array 10 :initial-element 0)))
    (dolist (result results)
      (let ((counts (second result)))
        (is (= rounds (aref counts 0)))
        (is (= (* 2 rounds) (aref counts 9)))
        (is (= (aref counts 0) (loop for i from 1 to 4 sum (aref counts i))))
        (is (= (aref counts 9) (+ (aref counts 5) (aref counts 6))))
        (dotimes (i 10)
          (incf (aref total i) (aref counts i))
          (incf (aref control i) (aref (fourth result) i)))))
    (is (= 4 (length results)))
    (is (= (* 4 rounds) (aref total 0)))
    (is (plusp (aref total 1))) (is (plusp (aref total 5))) (is (plusp (aref total 7)))
    (is (= 1 (aref control 0) (aref control 1) (aref control 5) (aref control 7)))
    (is (zerop (aref control 6)))
    (format t "  Cache v~D/~D byte: 4 worker, 32 record/8 vie; fase libera: tentativi ~D, inserted/present/busy/unavailable ~D/~D/~D/~D, hit/miss ~D/~D, espulsioni ~D, scan non riletti espulsi ~D; controllo del worker zero: 1 INSERTED, 1 HIT e 1 espulsione prima del rilascio comune. Rendezvous dopo un campione per worker; nessuna copertura delle finestre interne o misura di scaling.~%"
            version value-bytes (aref total 0) (aref total 1) (aref total 2)
            (aref total 3) (aref total 4) (aref total 5) (aref total 6)
            (aref total 7) (aref total 8)))
  t)

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-stress (version value-bytes)
  "Quattro worker reali con due rendezvous, poi carico misto limitato senza gate per operazione."
  (multiple-value-bind (cache entries) (cache-fixture version :count 32 :value-bytes value-bytes)
    (let* ((rounds 512) (deadline (cache-thread-deadline))
           (ready (map 'vector (lambda (i) (declare (ignore i)) (sb-thread:make-semaphore)) #(0 1 2 3)))
           (sampled (map 'vector (lambda (i) (declare (ignore i)) (sb-thread:make-semaphore)) #(0 1 2 3)))
           (buffers (map 'vector (lambda (i) (declare (ignore i)) (cache-buffer entries)) #(0 1 2 3)))
           (before (cache-thread-input-image entries))
           (start (sb-thread:make-semaphore)) (continue (sb-thread:make-semaphore))
           (threads nil) (results nil))
      (is (= 1 (c::classe-cache-sets (cache-class cache))))
      (is (= 8 (length (c::classe-cache-sequences (cache-class cache)))))
      (is (= 32 (length entries)))
      (cache-thread-fill-set cache entries)
      (unwind-protect
           (progn
             (dotimes (i 4)
               (let ((worker i))
                 (push (cache-thread-launch
                        (format nil "cache v~D value~D worker~D" version value-bytes worker)
                        (lambda () (cache-thread-stress-worker
                                    cache entries (svref buffers worker) worker rounds deadline (svref ready worker)
                                    start (svref sampled worker) continue))
                        (list (svref ready worker) (svref sampled worker))) threads)))
             (dotimes (i 4) (cache-thread-wait (svref ready i) deadline))
             (sb-thread:signal-semaphore start 4)
             (dotimes (i 4) (cache-thread-wait (svref sampled i) deadline))
             (sb-thread:signal-semaphore continue 4)
             (dolist (thread threads) (push (cache-thread-join thread deadline) results))
             (cache-thread-check-buffers (map 'vector #'third results) entries)
             (dolist (result results) (is (find (third result) buffers :test #'eq)))
             (cache-thread-check-input-image entries before)
             (cache-thread-report-stress results version value-bytes rounds))
        (cache-thread-cleanup threads (list start continue))))))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-lock-holder (lock held release deadline)
  "Detiene il vero mutex di striscia fino al gate esplicito; nessun timer decide il rilascio."
  (sb-thread:with-mutex (lock :timeout (cache-thread-seconds-left deadline))
    (sb-thread:signal-semaphore held)
    (cache-thread-wait release deadline)
    (return-from cache-thread-lock-holder (list :ok :released)))
  (error "Cache thread: acquisizione mutex del controllo fallita."))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(defun cache-thread-lock-probe (cache entries probed retry deadline)
  "BUSY deve tornare mentre un altro worker detiene il mutex; poi stesso worker riprende."
  (let ((entry (svref entries 0)) (buffer (cache-buffer entries)))
    (multiple-value-bind (status evicted polluted) (cache-insert cache entry)
      (is (eq :busy status)) (is (not evicted)) (is (not polluted)))
    (sb-thread:signal-semaphore probed)
    (cache-thread-wait retry deadline)
    (multiple-value-bind (status evicted polluted) (cache-insert cache entry)
      (is (eq :inserted status)) (is (not evicted)) (is (not polluted)))
    (is (eq :hit (cache-check-read cache entry buffer))))
  (list :ok :busy-then-inserted))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004 REQ-AFF-008
(defun cache-thread-held-lock (version)
  "Il runner attende BUSY prima di liberare il detentore; un inserimento bloccante scade."
  (multiple-value-bind (cache entries) (cache-fixture version :count 32 :value-bytes 16)
    (let* ((deadline (cache-thread-deadline)) (held (sb-thread:make-semaphore))
           (release (sb-thread:make-semaphore)) (probed (sb-thread:make-semaphore))
           (retry (sb-thread:make-semaphore))
           (lock (aref (c::classe-cache-locks (cache-class cache)) 0))
           (threads nil) (holder nil) (probe nil))
      (unwind-protect
           (progn
             (setf holder (cache-thread-launch
                           "cache controlled stripe holder"
                           (lambda () (cache-thread-lock-holder lock held release deadline)) (list held)))
             (push holder threads)
             (cache-thread-wait held deadline)
             (setf probe (cache-thread-launch
                          "cache controlled nonblocking insertion"
                          (lambda () (cache-thread-lock-probe cache entries probed retry deadline)) (list probed)))
             (push probe threads)
             (cache-thread-wait probed deadline)
             (sb-thread:signal-semaphore release)
             (is (eq :released (second (cache-thread-join holder deadline))))
             (sb-thread:signal-semaphore retry)
             (is (eq :busy-then-inserted (second (cache-thread-join probe deadline))))
             (format t "  Cache v~D: mutex detenuto da altro worker, BUSY completato prima del rilascio; stesso worker poi INSERTED e HIT verificato.~%" version))
        (cache-thread-cleanup threads (list release retry))))))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-004-cache-v1-four-workers-small-records
  (cache-thread-stress 1 16))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-004-cache-v2-four-workers-small-records
  (cache-thread-stress 2 16))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-004-cache-v1-four-workers-multi-kib-records
  (cache-thread-stress 1 4096))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-004-cache-v2-four-workers-multi-kib-records
  (cache-thread-stress 2 4096))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-004-cache-v1-other-thread-held-stripe-is-nonblocking
  (cache-thread-held-lock 1))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-004-cache-v2-other-thread-held-stripe-is-nonblocking
  (cache-thread-held-lock 2))
