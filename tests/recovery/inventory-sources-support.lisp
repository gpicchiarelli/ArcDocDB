;;;; C4: oracolo di ownership con FD virtuali privati e nessun override globale.
(in-package #:arcdocdb.recovery.tests)

(defstruct (frs-fixture (:constructor frs-make (names)))
  names parent (sets nil) (events nil) (opened nil) (sizes nil) hook
  (complete t) (missing nil))

(defun frs-event (fixture stage &rest args)
  (push (cons stage args) (frs-fixture-events fixture))
  (when (frs-fixture-hook fixture) (apply (frs-fixture-hook fixture) fixture stage args)))

(defun frs-forbidden (&rest args)
  (error "Effetto readonly vietato: ~S" args))

(defun frs-backend (fixture)
  (arcdocdb.io:make-backend
   (lambda (path mode) (declare (ignore path mode)) 71)
   (lambda (fd buffer start count offset)
     (declare (ignore fd offset)) (fill buffer 23 :start start :end (+ start count)) count)
   #'frs-forbidden #'frs-forbidden #'frs-forbidden
   (lambda (fd) (frs-event fixture :close fd) 0)
   :directory-entries
   (unless (eq (frs-fixture-missing fixture) :directory)
     (lambda (fd names total single)
       (is (= fd 71)) (frs-event fixture :enumerate names total single)
       (values (frs-fixture-names fixture) (frs-fixture-complete fixture))))
   :entry-identity
   (unless (eq (frs-fixture-missing fixture) :identity)
     (lambda (fd name)
       (is (= fd 71)) (frs-event fixture :entry (copy-seq name))
       (values 5 (1+ (position name (frs-fixture-names fixture) :test #'string=)))))
   :open-relative
   (unless (eq (frs-fixture-missing fixture) :relative)
     (lambda (fd name mode)
       (is (= fd 71)) (is (eq mode :input))
       (frs-event fixture :open (copy-seq name))
       (let ((child (+ 100 (length (frs-fixture-opened fixture)))))
         (push (cons child (copy-seq name)) (frs-fixture-opened fixture)) child)))
   :file-metadata
   (unless (eq (frs-fixture-missing fixture) :metadata)
     (lambda (fd)
       (frs-event fixture :metadata fd)
       (let* ((name (cdr (assoc fd (frs-fixture-opened fixture))))
              (position (position name (frs-fixture-names fixture) :test #'string=)))
         (values 5 (1+ position) (or (cdr (assoc name (frs-fixture-sizes fixture) :test #'string=)) 5)))))))

(defun frs-run (specs thunk &key missing sizes (mode :directory))
  (let* ((fixture (frs-make (idr-names specs)))
         (backend (progn (setf (frs-fixture-missing fixture) missing
                              (frs-fixture-sizes fixture) sizes) (frs-backend fixture)))
         (parent (if (eq mode :directory)
                     (arcdocdb.io:apri-directory "/sources" :backend backend)
                     (arcdocdb.io:apri-lettura "/sources" :backend backend))))
    (setf (frs-fixture-parent fixture) parent)
    (unwind-protect (funcall thunk fixture parent)
      (dolist (sources (frs-fixture-sets fixture))
        (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources))
      (arcdocdb.io:chiudi parent))))

(defun frs-open (fixture manifest &rest options)
  (multiple-value-bind (sources plan)
      (apply #'arcdocdb.recovery.manifest:apri-fonti-recovery
             manifest (frs-fixture-parent fixture) options)
    (push sources (frs-fixture-sets fixture)) (values sources plan)))

(defun frs-events (fixture stage)
  (reverse (remove-if-not (lambda (event) (eq stage (first event))) (frs-fixture-events fixture))))

(defun frs-files (sources)
  (loop for i below (arcdocdb.recovery.manifest:numero-fonti-recovery sources)
        collect (fourth (multiple-value-list (arcdocdb.recovery.manifest:fonte-recovery sources i)))))

(defun frs-check-closed (fixture files)
  (dolist (file files) (is (eq :closed (arcdocdb.io:stato-file file))))
  (dolist (pair (frs-fixture-opened fixture))
    (is (= 1 (count (list :close (car pair)) (frs-fixture-events fixture) :test #'equal))))
  (is (eq :open (arcdocdb.io:stato-file (frs-fixture-parent fixture)))))

(defun frs-original ()
  (make-condition 'arcdocdb.conditions:io-fault :reason :frs-injected
                  :operation :read :errno 9 :transferred 2))
