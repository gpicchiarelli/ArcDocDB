;;;; C4: backend privato per creazione esclusiva e registri bounded POSIX esistenti.
;;; OWNER: fixture seriale; parent preso in prestito, figli chiusi prima del parent.
;;; SHARED: nessuno; nessun override globale di funzioni di prodotto.
(in-package #:arcdocdb.io.tests)
(declaim (optimize (safety 3) (debug 3)))

(defstruct (ctr-fixture (:constructor ctr-make-fixture))
  "FD virtuali: nessuna syscall nei casi iniettati."
  parent (child-fd 73) (metadata (list 5 9 0)) (entry (list 5 9))
  create-hook metadata-hook entry-hook close-hook (events nil) (files nil))

(defun ctr-stage (fixture stage &rest arguments)
  (push (cons stage arguments) (ctr-fixture-events fixture))
  (let ((hook (ecase stage (:create (ctr-fixture-create-hook fixture))
                         (:metadata (ctr-fixture-metadata-hook fixture))
                         (:entry (ctr-fixture-entry-hook fixture)))))
    (when hook (apply hook fixture arguments))))

(defun ctr-forbidden (fixture operation &rest arguments)
  (push (cons operation arguments) (ctr-fixture-events fixture))
  (error "Operazione inattesa durante create-relative: ~S" operation))

(defun ctr-backend (fixture missing)
  "Le vecchie aperture e IDENTITY sono trappole, mai fallback della nuova API."
  (make-backend
   (lambda (path mode) (declare (ignore path mode)) 41)
   (lambda (&rest args) (apply #'ctr-forbidden fixture :read args))
   (lambda (fd buffer start count)
     (declare (ignore buffer start)) (is (= fd (ctr-fixture-child-fd fixture)))
     (push (list :write fd count) (ctr-fixture-events fixture)) count)
   (lambda (&rest args) (apply #'ctr-forbidden fixture :flush args))
   (lambda (&rest args) (apply #'ctr-forbidden fixture :directory-flush args))
   (lambda (fd)
     (push (list :close fd) (ctr-fixture-events fixture))
     (if (ctr-fixture-close-hook fixture) (funcall (ctr-fixture-close-hook fixture) fixture fd) 0))
   :identity (lambda (&rest args) (apply #'ctr-forbidden fixture :legacy-identity args))
   :open-relative (lambda (&rest args) (apply #'ctr-forbidden fixture :readonly-relative args))
   :create-relative (unless (eq missing :create)
                      (lambda (fd name mode)
                        (is (= fd 41)) (is (eq mode :append))
                        (ctr-stage fixture :create fd name mode) (ctr-fixture-child-fd fixture)))
   :file-metadata (unless (eq missing :metadata)
                    (lambda (fd) (is (= fd (ctr-fixture-child-fd fixture)))
                      (ctr-stage fixture :metadata fd) (values-list (ctr-fixture-metadata fixture))))
   :entry-identity (unless (eq missing :entry)
                     (lambda (fd name) (is (= fd 41))
                       (ctr-stage fixture :entry fd name) (values-list (ctr-fixture-entry fixture))))))

(defun ctr-run (thunk &key missing (mode :directory))
  (let* ((fixture (ctr-make-fixture)) (backend (ctr-backend fixture missing))
         (parent (ecase mode (:directory (apri-directory "/create-fixture" :backend backend))
                            (:input (apri-lettura "/create-fixture" :backend backend))
                            (:append (crea-temporaneo "/create-fixture.tmp" :backend backend)))))
    (setf (ctr-fixture-parent fixture) parent
          (arcdocdb.io::file-written parent) 23 (arcdocdb.io::file-durable parent) 17)
    (unwind-protect (funcall thunk fixture parent)
      (dolist (file (ctr-fixture-files fixture)) (chiudi file)) (chiudi parent))))

(defun ctr-call (parent name &rest options)
  "Argomenti invalidi dinamici: nessuna diagnostica costante del compilatore."
  (apply #'arcdocdb.io:crea-temporaneo-nella-directory parent name options))

(defun ctr-create (fixture &rest options)
  (let ((file (apply #'ctr-call (ctr-fixture-parent fixture) "payload.tmp" options)))
    (push file (ctr-fixture-files fixture)) file))

(defun ctr-count (fixture stage)
  (count stage (ctr-fixture-events fixture) :key #'first))

(defun ctr-closes (fixture fd)
  (count (list :close fd) (ctr-fixture-events fixture) :test #'equal))

(defun ctr-check-parent (parent &optional (state :open))
  (is (equal (list state 23 17) (rename-native-state parent)))
  (is (= 41 (arcdocdb.io::file-fd parent))))

(defun ctr-set-hook (fixture stage function)
  (ecase stage (:create (setf (ctr-fixture-create-hook fixture) function))
               (:metadata (setf (ctr-fixture-metadata-hook fixture) function))
               (:entry (setf (ctr-fixture-entry-hook fixture) function))))

(defun ctr-condition (type reason thunk)
  (handler-case (progn (funcall thunk) (error "Errore create-relative atteso: ~S" type))
    (arcdocdb.conditions:arcdocdb-error (condition)
      (is (typep condition type)) (is (eq reason (error-reason condition))) condition)))

(defun ctr-native-case (thunk)
  "Deadline cooperativa, cleanup dei soli nomi registrati, causa primaria conservata."
  (let ((fixture (rename-native-make-fixture)) (primary nil) (cleanup nil)
        (deadline (rename-native-deadline 30)))
    (handler-case (funcall thunk fixture deadline) (error (condition) (setf primary condition)))
    (handler-case (rename-native-cleanup fixture (rename-native-deadline 10))
      (error (condition) (setf cleanup condition)))
    (when cleanup (format *error-output* "Create-relative fixture cleanup: ~A~%" cleanup))
    (when primary (error primary)) (when cleanup (error cleanup))))

(defun ctr-native-create (fixture parent name deadline &rest options)
  "Il nome è registrato dal chiamante prima dell'effetto; il FD prima degli assert."
  (rename-native-seconds-left deadline :create-relative)
  (is (< (length (rename-native-fixture-files fixture)) +rename-native-file-limit+))
  (let ((file (apply #'arcdocdb.io:crea-temporaneo-nella-directory parent name options)))
    (push file (rename-native-fixture-files fixture))
    (rename-native-seconds-left deadline :create-relative) file))

(defun ctr-native-parent-observation (parent)
  "L'identità della directory resta stabile; la sua dimensione fisica può cambiare."
  (list (arcdocdb.io::file-fd parent) (rename-native-state parent) (rename-native-identity parent)))

(defun ctr-native-entry-observation (path)
  (let ((stat (sb-posix:lstat (namestring path))))
    (list (sb-posix:stat-dev stat) (sb-posix:stat-ino stat)
          (sb-posix:stat-mode stat) (sb-posix:stat-size stat))))
