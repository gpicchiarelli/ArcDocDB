;;;; C4: backend locale per ownership degli FD e fixture native già registrate.
;;; OWNER: fixture seriale; callback e nomi privati, nessun override globale.
;;; SHARED: nessuno; il parent resta preso in prestito durante ogni chiamata.
(in-package #:arcdocdb.io.tests)
(declaim (optimize (safety 3) (debug 3)))

(defstruct (orl-fixture (:constructor orl-make-fixture))
  "Solo FD virtuali nel backend C4; i test nativi usano il registro rename-native."
  parent (child-fd 73) (metadata (list 5 9 4)) (entry (list 5 9))
  (payload (bytes 7 0 255 19)) open-hook metadata-hook entry-hook close-hook
  (events nil) (files nil))

(defun orl-stage (fixture stage &rest arguments)
  "Registra prima del callback; nessuna operazione nativa o stato condiviso."
  (push (cons stage arguments) (orl-fixture-events fixture))
  (let ((hook (ecase stage (:relative (orl-fixture-open-hook fixture))
                         (:metadata (orl-fixture-metadata-hook fixture))
                         (:entry (orl-fixture-entry-hook fixture)))))
    (when hook (apply hook fixture arguments))))

(defun orl-forbidden (fixture operation &rest arguments)
  (push (cons operation arguments) (orl-fixture-events fixture))
  (error "Operazione readonly inattesa: ~S" operation))

(defun orl-backend (fixture missing)
  "Tre callback espliciti: IDENTITY legacy è una trappola, mai un fallback."
  (make-backend
   (lambda (path mode) (declare (ignore path mode)) 41)
   (lambda (fd buffer start count offset)
     (is (= fd (orl-fixture-child-fd fixture)))
     (let ((size (min count (max 0 (- (length (orl-fixture-payload fixture)) offset)))))
       (replace buffer (orl-fixture-payload fixture) :start1 start :end1 (+ start size)
                                                    :start2 offset :end2 (+ offset size)) size))
   (lambda (&rest args) (apply #'orl-forbidden fixture :write args))
   (lambda (&rest args) (apply #'orl-forbidden fixture :flush args))
   (lambda (&rest args) (apply #'orl-forbidden fixture :directory-flush args))
   (lambda (fd)
     (push (list :close fd) (orl-fixture-events fixture))
     (if (orl-fixture-close-hook fixture) (funcall (orl-fixture-close-hook fixture) fixture fd) 0))
   :identity (lambda (&rest args) (apply #'orl-forbidden fixture :legacy-identity args))
   :open-relative (unless (eq missing :relative)
                    (lambda (fd name mode)
                      (is (= fd 41)) (is (eq mode :input))
                      (orl-stage fixture :relative fd name mode) (orl-fixture-child-fd fixture)))
   :file-metadata (unless (eq missing :metadata)
                    (lambda (fd) (is (= fd (orl-fixture-child-fd fixture)))
                      (orl-stage fixture :metadata fd) (values-list (orl-fixture-metadata fixture))))
   :entry-identity (unless (eq missing :entry)
                     (lambda (fd name) (is (= fd 41))
                       (orl-stage fixture :entry fd name) (values-list (orl-fixture-entry fixture))))))

(defun orl-run (thunk &key missing (mode :directory))
  "Confine fixture: tutte le capacità restituite sono chiuse prima del parent."
  (let* ((fixture (orl-make-fixture)) (backend (orl-backend fixture missing))
         (parent (ecase mode (:directory (apri-directory "/relative-fixture" :backend backend))
                            (:input (apri-lettura "/relative-fixture" :backend backend))
                            (:append (crea-temporaneo "/relative-fixture.tmp" :backend backend)))))
    (setf (orl-fixture-parent fixture) parent
          (arcdocdb.io::file-written parent) 23 (arcdocdb.io::file-durable parent) 17)
    (unwind-protect (funcall thunk fixture parent)
      (dolist (file (orl-fixture-files fixture)) (chiudi file))
      (chiudi parent))))

(defun orl-open (fixture &rest options)
  "Registra il risultato prima di controllarne EOF; nessuna capacità parziale inventata."
  (multiple-value-bind (file eof)
      (apply #'arcdocdb.io:apri-lettura-nella-directory (orl-fixture-parent fixture) "payload.seg" options)
    (push file (orl-fixture-files fixture)) (values file eof)))

(defun orl-call (parent name &rest options)
  "Passaggio dinamico dei valori invalidi: nessuna diagnostica costante del compilatore."
  (apply #'arcdocdb.io:apri-lettura-nella-directory parent name options))

(defun orl-count (fixture stage)
  (count stage (orl-fixture-events fixture) :key #'first))

(defun orl-closes (fixture fd)
  (count (list :close fd) (orl-fixture-events fixture) :test #'equal))

(defun orl-check-parent (parent &optional (state :open))
  (is (equal (list state 23 17) (rename-native-state parent)))
  (is (= 41 (arcdocdb.io::file-fd parent))))

(defun orl-set-hook (fixture stage function)
  (ecase stage (:relative (setf (orl-fixture-open-hook fixture) function))
               (:metadata (setf (orl-fixture-metadata-hook fixture) function))
               (:entry (setf (orl-fixture-entry-hook fixture) function))))

(defun orl-condition (type reason thunk)
  "Cattura solo errori tipizzati; il helper signals esistente e' assert-only."
  (handler-case (progn (funcall thunk) (error "Errore open-relative atteso: ~S" type))
    (arcdocdb.conditions:arcdocdb-error (condition)
      (is (typep condition type)) (is (eq reason (error-reason condition))) condition)))

(defun orl-throw-primary (fixture stage original)
  "Guasto di dipendenza: la stessa condizione attraversa cleanup riuscito senza wrapper."
  (orl-set-hook fixture stage (lambda (&rest args) (declare (ignore args)) (error original)))
  (is (eq original (orl-condition 'arcdocdb.conditions:arcdocdb-error (error-reason original)
                                (lambda () (orl-open fixture)))))
  (is (= (if (eq stage :relative) 0 1) (orl-closes fixture 73)))
  (orl-check-parent (orl-fixture-parent fixture)))

(defun orl-native-case (thunk)
  "Harness seriale C4: deadline cooperativa; cleanup registra il secondario e conserva la causa."
  (let ((fixture (rename-native-make-fixture)) (primary nil) (cleanup nil)
        (deadline (rename-native-deadline 30)))
    (handler-case (funcall thunk fixture deadline) (error (condition) (setf primary condition)))
    (handler-case (rename-native-cleanup fixture (rename-native-deadline 10))
      (error (condition) (setf cleanup condition)))
    (when cleanup (format *error-output* "Open-relative fixture cleanup: ~A~%" cleanup))
    (when primary (error primary)) (when cleanup (error cleanup))))

(defun orl-native-open (fixture parent name deadline &rest options)
  "Deadline cooperativa prima dell'apertura; capacità registrata prima di ogni assert."
  (rename-native-seconds-left deadline :open-relative)
  (is (< (length (rename-native-fixture-files fixture)) +rename-native-file-limit+))
  (multiple-value-bind (file eof) (apply #'arcdocdb.io:apri-lettura-nella-directory parent name options)
    (push file (rename-native-fixture-files fixture))
    (rename-native-seconds-left deadline :open-relative)
    (values file eof)))

(defun orl-native-observation (file)
  "FD, identità, EOF fisico e frontiere del file già posseduto."
  (list (arcdocdb.io::file-fd file) (rename-native-state file) (rename-native-identity file)
        (sb-posix:stat-size (sb-posix:fstat (arcdocdb.io::file-fd file)))))
